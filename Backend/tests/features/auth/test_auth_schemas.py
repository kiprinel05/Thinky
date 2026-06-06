"""Pydantic validation tests for auth schemas. No DB, no services — pure validation."""
import pytest
from pydantic import ValidationError

from features.auth.schemas import (
    GuestRegister,
    PasswordResetConfirm,
    PasswordResetVerify,
    UserLogin,
    UserRegister,
)


class TestUserRegister:
    def test_valid_payload_is_accepted(self):
        # Arrange / Act
        user = UserRegister(
            username="cipri",
            email="cipri@example.com",
            password="secret123",
            confirm_password="secret123",
        )
        # Assert
        assert user.username == "cipri"
        assert user.email == "cipri@example.com"
        assert user.password == "secret123"

    def test_username_is_stripped(self):
        user = UserRegister(
            username="  cipri  ",
            email="a@b.com",
            password="secret123",
            confirm_password="secret123",
        )
        assert user.username == "cipri"

    def test_username_too_short_raises(self):
        with pytest.raises(ValidationError) as exc_info:
            UserRegister(
                username="ab",
                email="a@b.com",
                password="secret123",
                confirm_password="secret123",
            )
        assert "at least 3 characters" in str(exc_info.value)

    def test_username_too_long_raises(self):
        with pytest.raises(ValidationError) as exc_info:
            UserRegister(
                username="x" * 51,
                email="a@b.com",
                password="secret123",
                confirm_password="secret123",
            )
        assert "less than 50 characters" in str(exc_info.value)

    def test_password_too_short_raises(self):
        with pytest.raises(ValidationError) as exc_info:
            UserRegister(
                username="cipri",
                email="a@b.com",
                password="12345",
                confirm_password="12345",
            )
        assert "at least 6 characters" in str(exc_info.value)

    def test_mismatched_confirm_password_raises(self):
        with pytest.raises(ValidationError) as exc_info:
            UserRegister(
                username="cipri",
                email="a@b.com",
                password="secret123",
                confirm_password="DIFFERENT1",
            )
        assert "Passwords do not match" in str(exc_info.value)

    def test_invalid_email_raises(self):
        with pytest.raises(ValidationError):
            UserRegister(
                username="cipri",
                email="not-an-email",
                password="secret123",
                confirm_password="secret123",
            )


class TestUserLogin:
    def test_valid_payload(self):
        login = UserLogin(email="a@b.com", password="anypass")
        assert login.email == "a@b.com"
        assert login.password == "anypass"

    def test_invalid_email_raises(self):
        with pytest.raises(ValidationError):
            UserLogin(email="bad", password="anypass")


class TestGuestRegister:
    def test_valid_name(self):
        guest = GuestRegister(name="Ana")
        assert guest.name == "Ana"

    def test_name_is_stripped(self):
        guest = GuestRegister(name="  Ana  ")
        assert guest.name == "Ana"

    def test_empty_name_raises(self):
        with pytest.raises(ValidationError):
            GuestRegister(name="   ")


class TestPasswordResetVerify:
    def test_valid_code(self):
        m = PasswordResetVerify(email="a@b.com", code="123456")
        assert m.code == "123456"

    def test_wrong_length_raises(self):
        with pytest.raises(ValidationError):
            PasswordResetVerify(email="a@b.com", code="12345")

    def test_non_digit_raises(self):
        with pytest.raises(ValidationError):
            PasswordResetVerify(email="a@b.com", code="12345a")


class TestPasswordResetConfirm:
    def test_valid_payload(self):
        m = PasswordResetConfirm(
            email="a@b.com", code="123456", new_password="newpass1"
        )
        assert m.new_password == "newpass1"

    def test_short_password_raises(self):
        with pytest.raises(ValidationError):
            PasswordResetConfirm(
                email="a@b.com", code="123456", new_password="abc"
            )

    def test_bad_code_raises(self):
        with pytest.raises(ValidationError):
            PasswordResetConfirm(
                email="a@b.com", code="12abcd", new_password="newpass1"
            )
