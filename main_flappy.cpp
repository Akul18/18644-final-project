// Flappy Bird Verilator + SDL simulation
// Based on the Project F SDL simulation structure

#include <cstdio>
#include <cstdint>
#include <SDL.h>
#include <verilated.h>
#include "Vtop_flappy_sim.h"

// screen dimensions
static const int H_RES = 640;
static const int V_RES = 480;

struct Pixel {
    uint8_t a;
    uint8_t b;
    uint8_t g;
    uint8_t r;
};

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        std::printf("SDL init failed: %s\n", SDL_GetError());
        return 1;
    }

    Pixel screenbuffer[H_RES * V_RES] = {};

    SDL_Window* sdl_window = SDL_CreateWindow(
        "Flappy Bird Simulation",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        H_RES,
        V_RES,
        SDL_WINDOW_SHOWN
    );
    if (!sdl_window) {
        std::printf("Window creation failed: %s\n", SDL_GetError());
        SDL_Quit();
        return 1;
    }

    SDL_Renderer* sdl_renderer = SDL_CreateRenderer(
        sdl_window,
        -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    );
    if (!sdl_renderer) {
        std::printf("Renderer creation failed: %s\n", SDL_GetError());
        SDL_DestroyWindow(sdl_window);
        SDL_Quit();
        return 1;
    }

    SDL_Texture* sdl_texture = SDL_CreateTexture(
        sdl_renderer,
        SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_STREAMING,
        H_RES,
        V_RES
    );
    if (!sdl_texture) {
        std::printf("Texture creation failed: %s\n", SDL_GetError());
        SDL_DestroyRenderer(sdl_renderer);
        SDL_DestroyWindow(sdl_window);
        SDL_Quit();
        return 1;
    }

    std::printf("Simulation running.\n");
    std::printf("Controls:\n");
    std::printf("  S     = start game\n");
    std::printf("  SPACE = jump\n");
    std::printf("  R     = reset\n");
    std::printf("  Q     = quit\n\n");

    Vtop_flappy_sim* top = new Vtop_flappy_sim;

    // initialize inputs
    top->clk_pix   = 0;
    top->sim_rst   = 1;
    top->btn_start = 0;
    top->btn_jump  = 0;

    // apply reset for a few cycles
    for (int i = 0; i < 4; i++) {
        top->clk_pix = 0;
        top->eval();
        top->clk_pix = 1;
        top->eval();
    }

    top->sim_rst = 0;

    uint64_t start_ticks = SDL_GetPerformanceCounter();
    uint64_t frame_count = 0;
    bool running = true;

    while (running && !Verilated::gotFinish()) {
        // process all SDL events so keyboard state stays current
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) {
                running = false;
            }
        }

        SDL_PumpEvents();
        const Uint8* keyb_state = SDL_GetKeyboardState(NULL);

        if (keyb_state[SDL_SCANCODE_Q]) {
            running = false;
        }

        // map keyboard to Verilog inputs
        top->btn_start = keyb_state[SDL_SCANCODE_S] ? 1 : 0;
        top->btn_jump  = keyb_state[SDL_SCANCODE_SPACE] ? 1 : 0;
        top->sim_rst   = keyb_state[SDL_SCANCODE_R] ? 1 : 0;

        // cycle the clock
        top->clk_pix = 0;
        top->eval();

        top->clk_pix = 1;
        top->eval();

        // write visible pixels into the screenbuffer
        if (top->sdl_de) {
            if (top->sdl_sx < H_RES && top->sdl_sy < V_RES) {
                Pixel* p = &screenbuffer[top->sdl_sy * H_RES + top->sdl_sx];
                p->a = 0xFF;
                p->b = top->sdl_b;
                p->g = top->sdl_g;
                p->r = top->sdl_r;
            }
        }

        // present once per frame
        if (top->sdl_sy == V_RES && top->sdl_sx == 0) {
            SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES * sizeof(Pixel));
            SDL_RenderClear(sdl_renderer);
            SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
            SDL_RenderPresent(sdl_renderer);
            frame_count++;
        }
    }

    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = static_cast<double>(end_ticks - start_ticks) /
                      static_cast<double>(SDL_GetPerformanceFrequency());
    double fps = (duration > 0.0) ? static_cast<double>(frame_count) / duration : 0.0;

    std::printf("Frames per second: %.1f\n", fps);

    top->final();
    delete top;

    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();

    return 0;
}