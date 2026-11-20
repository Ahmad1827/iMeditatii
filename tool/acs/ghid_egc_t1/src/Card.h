#pragma once

#include <string>

#include "utils/glm_utils.h"


namespace tema1
{
    enum Zone { DECK, HAND, BOARD, DEAD };

    enum CardType { NORMAL, TANK, CHARGE, LIFESTEAL, SILENCE, TYPE_COUNT };

    enum Effect { EFFECT_NONE, EFFECT_TANK, EFFECT_CHARGE, EFFECT_LIFESTEAL, EFFECT_SILENCE };

    struct TypeStyle
    {
        glm::vec3 color;
        std::string shape;
        int manaCost;
        Effect effect;
    };

    inline TypeStyle GetTypeStyle(CardType type)
    {
        switch (type) {
            case TANK:      return { glm::vec3(0.25f, 0.45f, 0.85f), "diamond", 4, EFFECT_TANK };
            case CHARGE:    return { glm::vec3(0.90f, 0.50f, 0.10f), "triangle", 3, EFFECT_CHARGE };
            case LIFESTEAL: return { glm::vec3(0.75f, 0.15f, 0.20f), "plus", 3, EFFECT_LIFESTEAL };
            case SILENCE:   return { glm::vec3(0.55f, 0.25f, 0.75f), "star", 2, EFFECT_SILENCE };
            default:        return { glm::vec3(0.55f, 0.55f, 0.55f), "circle", 1, EFFECT_NONE };
        }
    }

    struct Card
    {
        Zone zone = DECK;
        bool isEnemy = false;
        bool isDragged = false;
        bool isSelected = false;
        bool hasAttacked = false;
        bool isHovered = false;

        int atk = 0;
        int hp = 0;
        int manaCost = 0;
        int round = -1;

        CardType type = NORMAL;
        Effect effect = EFFECT_NONE;

        float x = 0;
        float y = 0;

        float targetX = 0;
        float targetY = 0;

        float w = 0;
        float h = 0;
        float targetW = 0;
        float targetH = 0;

        float angle = 0;
        float shakeTimer = 0;
    };
}
