#pragma once

#include <string>

#include "core/gpu/mesh.h"
#include "utils/glm_utils.h"


namespace tema1 {
namespace shapes
{
    Mesh* CreatePlus(const std::string& name);

    Mesh* CreateTriangle(const std::string& name);

    Mesh* CreateStar(const std::string& name);

    Mesh* CreateCircle(const std::string& name, int segments = 48);

    Mesh* CreateDiamond(const std::string& name);

    Mesh* CreateArrow(const std::string& name);

    Mesh* CreateHeart(const std::string& name, int segments = 64);

    Mesh* CreateSword(const std::string& name, int segments = 64);
} 
} 
