shader_type particles;

uniform float radius = 0.3;          // Radius of individual hexagon
uniform float spacing = 0.25;        // Gap between hexagons
uniform float sphere_radius = 3.0;   // Radius of the spherical shield dome
uniform float hex_rotation_deg = 0.0; // Adjust (e.g. 0.0 or 30.0) to align edges

void start() {
    float hex_spacing = radius + spacing;
    int idx = int(INDEX);
    
    int q = 0;
    int r = 0;
    
    if (idx > 0) {
        int ring = int(floor((3.0 + sqrt(12.0 * float(idx) - 3.0)) / 6.0));
        int ring_start = 3 * ring * ring - 3 * ring + 1;
        int ring_offset = idx - ring_start;
        
        int side = ring_offset / ring;
        int step = ring_offset % ring;
        
        int dq[6] = int[](1, 0, -1, -1, 0, 1);
        int dr[6] = int[](0, 1, 1, 0, -1, -1);
        int corner_q[6] = int[](0, 1, 1, 0, -1, -1);
        int corner_r[6] = int[](-1, -1, 0, 1, 1, 0);
        
        q = corner_q[side] * ring + dq[side] * step;
        r = corner_r[side] * ring + dr[side] * step;
    }
    
    // 1. Compute flat XZ grid coordinates
    float pos_x = hex_spacing * (float(q) + 0.5 * float(r));
    float pos_z = hex_spacing * (float(r) * 0.8660254);
    
    float d = length(vec2(pos_x, pos_z));
    vec3 final_pos = vec3(0.0);
    
    // In-plane yaw rotation for individual hexagon tile
    float yaw = radians(hex_rotation_deg);
    mat3 local_yaw = mat3(
        vec3(cos(yaw), 0.0, -sin(yaw)),
        vec3(0.0, 1.0, 0.0),
        vec3(sin(yaw), 0.0, cos(yaw))
    );
    
    mat3 rot = local_yaw;
    
    if (d > 0.0001) {
        vec2 dir = vec2(pos_x, pos_z) / d;
        float angle = d / sphere_radius; // Spherical tilt angle
        
        // 2. Dome position in local space
        final_pos.x = sphere_radius * sin(angle) * dir.x;
        final_pos.z = sphere_radius * sin(angle) * dir.y;
        final_pos.y = sphere_radius * cos(angle) - sphere_radius;
        
        // 3. Tangent-to-Sphere Rotation Matrix
        float c = cos(angle);
        float s = sin(angle);
        float C = 1.0 - c;
        
        vec3 col0 = vec3(dir.y * dir.y * C + c, -dir.x * s, -dir.x * dir.y * C);
        vec3 col1 = vec3(dir.x * s, c, dir.y * s);
        vec3 col2 = vec3(-dir.x * dir.y * C, -dir.y * s, dir.x * dir.x * C + c);
        
        rot = mat3(col0, col1, col2) * local_yaw;
    }
    
    // 4. Construct local particle transform matrix
    mat4 local_transform = mat4(
        vec4(rot[0], 0.0),
        vec4(rot[1], 0.0),
        vec4(rot[2], 0.0),
        vec4(final_pos, 1.0)
    );
    
    // 5. Apply the Emitter Node's position, rotation, and scale in world space
    TRANSFORM = EMISSION_TRANSFORM * local_transform;
}