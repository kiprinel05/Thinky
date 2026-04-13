from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse
from typing import List, Optional
from .schemas import (
    RoundResponse,
    GuessRequest,
    GuessResponse,
    VerifyGuessRequest,
    VerifyGuessResponse,
    TeachingImagesResponse,
    ValidateTeachingRequest,
    ValidateTeachingResponse,
    MissionProgressResponse
)
from .service import get_animal_service, AnimalMissionService

router = APIRouter(prefix="/animals", tags=["animals"])

_session_state = {
    "current_round": 0,
    "total_rounds": 5,
    "used_image_ids": [],
    "correct_guesses": 0,
    "teaching_correct_ids": [],
    "pixy_skill": AnimalMissionService.SKILL_INITIAL,
}


def _reset_session():
    _session_state.update({
        "current_round": 0,
        "total_rounds": 5,
        "used_image_ids": [],
        "correct_guesses": 0,
        "teaching_correct_ids": [],
        "pixy_skill": AnimalMissionService.SKILL_INITIAL,
    })


@router.get("/start")
async def start_mission() -> MissionProgressResponse:
    _reset_session()
    return MissionProgressResponse(
        current_round=1,
        total_rounds=5,
        completed_rounds=0,
        pixy_accuracy=0.0,
        is_complete=False
    )


@router.get("/round")
async def get_round() -> RoundResponse:
    service = get_animal_service()

    if _session_state["current_round"] >= _session_state["total_rounds"]:
        raise HTTPException(status_code=400, detail="Mission already complete")

    image = service.get_random_image(exclude_ids=_session_state["used_image_ids"])
    _session_state["used_image_ids"].append(image.id)
    _session_state["current_round"] += 1

    return RoundResponse(
        round_number=_session_state["current_round"],
        total_rounds=_session_state["total_rounds"],
        image=image
    )


@router.post("/guess")
async def make_guess(request: GuessRequest) -> GuessResponse:
    service = get_animal_service()
    response = service.make_guess(
        request.image_id,
        skill_level=_session_state["pixy_skill"],
    )

    if response.is_correct:
        _session_state["correct_guesses"] += 1

    return response


@router.post("/verify-guess")
async def verify_guess(request: VerifyGuessRequest) -> VerifyGuessResponse:
    actual_animal = request.image_id.split("_")[0]
    was_actually_correct = (request.pixy_guess.lower() == actual_animal.lower())
    user_was_right = (request.user_says_correct == was_actually_correct)

    if user_was_right:
        if was_actually_correct:
            message = "Correct! Pixy got it right! 🎉"
        else:
            message = f"You're right, Pixy was wrong! The animal is a {actual_animal}. Let's teach Pixy!"
    else:
        if was_actually_correct:
            message = f"Actually, Pixy was correct! It is a {actual_animal}. Look more carefully!"
        else:
            message = f"Actually, Pixy was wrong! It's not a {request.pixy_guess}, it's a {actual_animal}."

    return VerifyGuessResponse(
        was_actually_correct=was_actually_correct,
        user_was_right=user_was_right,
        message=message
    )


@router.get("/teaching")
async def get_teaching_images(animal: str = Query(..., description="Target animal to teach")) -> TeachingImagesResponse:
    service = get_animal_service()
    response = service.get_teaching_images(animal, count=6)
    _session_state["teaching_correct_ids"] = response.correct_image_ids
    return response


@router.post("/validate-teaching")
async def validate_teaching(request: ValidateTeachingRequest) -> ValidateTeachingResponse:
    service = get_animal_service()
    correct_ids = _session_state.get("teaching_correct_ids", [])

    result = service.validate_teaching(
        target_animal=request.target_animal,
        selected_ids=request.selected_image_ids,
        correct_ids=correct_ids
    )

    if result.is_correct:
        new_skill = min(
            _session_state["pixy_skill"] + AnimalMissionService.SKILL_INCREMENT,
            AnimalMissionService.SKILL_CAP,
        )
        _session_state["pixy_skill"] = round(new_skill, 2)

    return result


@router.get("/progress")
async def get_progress() -> MissionProgressResponse:
    completed = _session_state["current_round"]
    correct = _session_state["correct_guesses"]
    accuracy = correct / max(completed, 1)

    return MissionProgressResponse(
        current_round=_session_state["current_round"] + 1,
        total_rounds=_session_state["total_rounds"],
        completed_rounds=completed,
        pixy_accuracy=round(accuracy, 2),
        is_complete=(completed >= _session_state["total_rounds"])
    )


@router.get("/image/{animal}/{filename}")
async def get_image(animal: str, filename: str):
    service = get_animal_service()
    image_path = service.get_image_path(animal, filename)

    if not image_path.exists():
        raise HTTPException(status_code=404, detail="Image not found")

    return FileResponse(image_path, media_type="image/jpeg")
