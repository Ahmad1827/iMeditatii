#include "lab_m1/Tema1/Tema1.h"

using namespace std;
using namespace m1;
using namespace tema1;


void Tema1::UpdateTimer(float deltaTime)
{
    if (gameOver) {
        return;
    }

    turnTimer -= deltaTime;
    if (turnTimer <= 0) {
        turnTimer = 0;
        EndTurn();
    }
}


void Tema1::DrawTimer()
{
    float y = enemyTimerY;
    if (player.isMyTurn) {
        y = playerTimerY;
    }

    float border = timerH * 0.2f;
    float width = timerW * turnTimer / turnTime;

    DrawRect(timerX - border, y - border, timerW + 2 * border, timerH + 2 * border, glm::vec3(0.05f, 0.05f, 0.05f));
    DrawRect(timerX, y, timerW, timerH, glm::vec3(0.3f, 0.3f, 0.3f));
    DrawRect(timerX, y, width, timerH, glm::vec3(1.0f, 0.75f, 0.2f));
}
