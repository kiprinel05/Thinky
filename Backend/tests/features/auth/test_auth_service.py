"""Service-layer tests for AuthService. Repository is mocked; bcrypt + JWT are real."""
from unittest.mock import MagicMock

import pytest
from jose import jwt

from core.config import settings
from core.security import verify_password
from features.auth.models import User
from features.auth.schemas import GuestRegister, UserLogin, UserRegister
from features.auth.service import AuthService


@pytest.fixture
def auth_service():
    """AuthService with a fully mocked repository (so no DB needed)."""
    mock_repo = MagicMock()
    mock_repo.db = MagicMock()
    return AuthService(mock_repo)


def _valid_register() -> UserRegister:
    return UserRegister(
        username="cipri",
        email="cipri@example.com",
        password="secret123",
        confirm_password="secret123",
    )


class TestAuthServiceRegister:
    def test_register_creates_user_with_hashed_password(self, auth_service):
        # Arrange: no existing user with the same email/username
        auth_service.repository.get_by_email.return_value = None
        auth_service.repository.get_by_username.return_value = None

        # Act
        auth_service.register(_valid_register())

        # Assert: db.add was called with a User whose password is bcrypt-hashed
        auth_service.repository.db.add.assert_called_once()
        added_user = auth_service.repository.db.add.call_args[0][0]
        assert isinstance(added_user, User)
        assert added_user.username == "cipri"
        assert added_user.email == "cipri@example.com"
        assert added_user.is_guest is False
        # Password must be hashed (different from plain) and verify back to plain.
        assert added_user.hashed_password != "secret123"
        assert verify_password("secret123", added_user.hashed_password)
        auth_service.repository.db.commit.assert_called_once()
        auth_service.repository.db.refresh.assert_called_once()

    def test_register_rejects_duplicate_email(self, auth_service):
        auth_service.repository.get_by_email.return_value = User(id=1, email="cipri@example.com")

        with pytest.raises(ValueError) as exc_info:
            auth_service.register(_valid_register())
        assert "Email already registered" in str(exc_info.value)
        auth_service.repository.db.add.assert_not_called()

    def test_register_rejects_duplicate_username(self, auth_service):
        auth_service.repository.get_by_email.return_value = None
        auth_service.repository.get_by_username.return_value = User(id=1, username="cipri")

        with pytest.raises(ValueError) as exc_info:
            auth_service.register(_valid_register())
        assert "Username already taken" in str(exc_info.value)
        auth_service.repository.db.add.assert_not_called()


class TestAuthServiceLogin:
    def _real_user(self, plain_password: str = "secret123", **overrides) -> User:
        from core.security import get_password_hash
        u = User(
            id=42,
            username="cipri",
            email="cipri@example.com",
            hashed_password=get_password_hash(plain_password),
            is_guest=False,
            is_admin=False,
        )
        for k, v in overrides.items():
            setattr(u, k, v)
        return u

    def test_login_returns_token_on_valid_credentials(self, auth_service):
        # Arrange
        auth_service.repository.get_by_email.return_value = self._real_user()

        # Act
        result = auth_service.login(
            UserLogin(email="cipri@example.com", password="secret123")
        )

        # Assert: token decodes back to this user
        assert result is not None
        assert result.is_guest is False
        assert result.user_id == 42
        payload = jwt.decode(
            result.access_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        assert payload["sub"] == "42"
        assert payload["email"] == "cipri@example.com"

    def test_login_returns_none_when_user_missing(self, auth_service):
        auth_service.repository.get_by_email.return_value = None
        assert auth_service.login(
            UserLogin(email="ghost@example.com", password="anything1")
        ) is None

    def test_login_returns_none_for_guest_account(self, auth_service):
        auth_service.repository.get_by_email.return_value = self._real_user(
            is_guest=True, hashed_password=None
        )
        assert auth_service.login(
            UserLogin(email="cipri@example.com", password="anything1")
        ) is None

    def test_login_returns_none_on_wrong_password(self, auth_service):
        auth_service.repository.get_by_email.return_value = self._real_user(
            plain_password="theright1"
        )
        assert auth_service.login(
            UserLogin(email="cipri@example.com", password="thewrong1")
        ) is None


class TestAuthServiceRegisterGuest:
    def test_register_guest_persists_and_returns_token(self, auth_service):
        # When db.refresh is called we have to actually populate the .id like SQLAlchemy would.
        def _set_id(user):
            user.id = 7
        auth_service.repository.db.refresh.side_effect = _set_id

        # Act
        token = auth_service.register_guest(GuestRegister(name="Ana"))

        # Assert
        assert token.is_guest is True
        assert token.user_id == 7
        assert token.guest_name == "Ana"
        auth_service.repository.db.add.assert_called_once()
        added_guest = auth_service.repository.db.add.call_args[0][0]
        assert added_guest.is_guest is True
        assert added_guest.guest_name == "Ana"
        assert added_guest.hashed_password is None
        assert added_guest.username.startswith("guest_")
        assert added_guest.email.endswith("@thinky.local")
        # JWT payload should mark guest
        payload = jwt.decode(
            token.access_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        assert payload["is_guest"] is True


class TestAuthServiceVerifyResetCode:
    def test_returns_false_when_user_missing(self, auth_service):
        auth_service.repository.get_by_email.return_value = None
        assert auth_service.verify_reset_code("ghost@example.com", "123456") is False

    def test_returns_true_when_code_is_valid(self, auth_service):
        auth_service.repository.get_by_email.return_value = User(id=1, email="x@y.com")
        auth_service.repository.get_valid_reset_code.return_value = MagicMock()
        assert auth_service.verify_reset_code("x@y.com", "123456") is True

    def test_returns_false_when_code_invalid(self, auth_service):
        auth_service.repository.get_by_email.return_value = User(id=1, email="x@y.com")
        auth_service.repository.get_valid_reset_code.return_value = None
        assert auth_service.verify_reset_code("x@y.com", "000000") is False
