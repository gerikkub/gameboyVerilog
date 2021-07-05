
#include <cstdio>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "obj_dir/Vgb_interconnect.h"

#include "gtest/gtest.h"

#include <SDL2/SDL.h>

typedef struct {
    Vgb_interconnect* dut;
    VerilatedVcdC* tfp;
    VerilatedContext* contextp;
} vgb_context_t;

void run_eval(vgb_context_t* ctx) {
    ctx->contextp->timeInc(1);
    ctx->dut->eval();
    if (ctx->tfp) {
        ctx->tfp->dump(ctx->contextp->time());
    }
}

void run_reset(vgb_context_t* ctx) {

    ctx->dut->reset = 0;
    ctx->dut->clock = 0;
    run_eval(ctx);

    ctx->dut->clock = 1;
    run_eval(ctx);
    ctx->dut->clock = 0;
    run_eval(ctx);
    ctx->dut->clock = 1;
    run_eval(ctx);

    ctx->dut->reset = 1;
}

void run_cycle(vgb_context_t* ctx) {

    ctx->dut->clock = 0;
    run_eval(ctx);

    ctx->dut->clock = 1;
    run_eval(ctx);
}

bool run_test(std::string test_filename, uint64_t timeout, std::string log_name, bool video = false);
void update_lcd(vgb_context_t* ctx);

TEST(INDIVIDUAL, 01) {
    bool res = run_test("test_roms/cpu_instrs/individual/01/01-special.gb", 10000000, "", true);
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 02) {
    bool res = run_test("test_roms/cpu_instrs/individual/02/02-interrupts.gb", 11000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 03) {
    bool res = run_test("test_roms/cpu_instrs/individual/03/03-op sp,hl.gb", 11000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 04) {
    bool res = run_test("test_roms/cpu_instrs/individual/04/04-op r,imm.gb", 100000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 05) {
    bool res = run_test("test_roms/cpu_instrs/individual/05/05-op rp.gb", 100000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 06) {
    bool res = run_test("test_roms/cpu_instrs/individual/06/06-ld r,r.gb", 11000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 07) {
    bool res = run_test("test_roms/cpu_instrs/individual/07/07-jr,jp,call,ret,rst.gb", 11000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 08) {
    bool res = run_test("test_roms/cpu_instrs/individual/08/08-misc instrs.gb", 11000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 09) {
    bool res = run_test("test_roms/cpu_instrs/individual/09/09-op r,r.gb", 1000000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 10) {
    bool res = run_test("test_roms/cpu_instrs/individual/10/10-bit ops.gb", 100000000, "");
    EXPECT_TRUE(res);
}

TEST(INDIVIDUAL, 11) {
    bool res = run_test("test_roms/cpu_instrs/individual/11/11-op a,(hl).gb", 100000000, "");
    EXPECT_TRUE(res);
}

struct {
    SDL_Window* window;
    SDL_mutex* renderer_lock;

    SDL_mutex* signal_lock;
    SDL_cond* signal;

    bool should_quit;
    bool have_update;
    SDL_Surface* draw_surface;
} g_lcd_display;


bool run_test(std::string test_filename, uint64_t timeout, std::string log_name, bool video) {

    int rom_fd = open(test_filename.c_str(), O_RDONLY);
    uint8_t* rom_mmap_f = static_cast<uint8_t*>(mmap(NULL, 0x8000, PROT_READ, MAP_PRIVATE, rom_fd, 0));
    assert(rom_mmap_f != NULL);
    close(rom_fd);

    Verilated::traceEverOn(true);
    Vgb_interconnect* dut = new Vgb_interconnect();
    VerilatedContext* contextp = new VerilatedContext();
    VerilatedVcdC* tfp = nullptr;
    if (log_name.length() > 0) {
        tfp = new VerilatedVcdC;
        dut->trace(tfp, 99);
        tfp->open(log_name.c_str());
    }
    vgb_context_t ctx = {
        .dut = dut,
        .tfp = tfp,
        .contextp = contextp,
    };

    uint64_t count = 0;

    bool test_passed;
    int passed_idx = 0;

    run_reset(&ctx);
    while (!Verilated::gotFinish()) {
        run_cycle(&ctx);
        count++;

        const char* passed = "Passed";

        //printf("%4X: %2X\n", dut->data_out, dut->address_out);
        //printf("%4X\n", dut->gb_interconnect__DOT__core__DOT__pc_mod__DOT__pc_register);
        if (ctx.dut->address_out == 0xFF01 &&
            ctx.dut->nwrite_out == 0 &&
            ctx.dut->data_out != 0) {
            printf("%c", ctx.dut->data_out);
            fflush(stdout);

            if (ctx.dut->data_out == passed[passed_idx]) {
                passed_idx++;
                if (passed[passed_idx] == '\0') {
                    test_passed = true;
                    break;
                }
            }
        }

        if (ctx.dut->nsel_rom_out == 0 &&
            ctx.dut->nread_out == 0) {
            
            assert(ctx.dut->address_out < 0x8000);

            ctx.dut->rom_data = rom_mmap_f[ctx.dut->address_out];
        }

        if (video) {
            update_lcd(&ctx);
        }

        if (count % 1000000 == 0) {
            printf("%lu\n", count);
        }

        if (count >= timeout) {
            test_passed = false;
            break;
        }
    }

    munmap(rom_mmap_f, 0x8000);

    ctx.dut->final();

    return test_passed;
}


void update_lcd(vgb_context_t* ctx) {

    uint32_t palette[4] = {
        0xFF202020,
        0xFF606060,
        0xFFA0A0A0,
        0xFFFFFFFF
    };

    static SDL_Surface* temp_surface = SDL_CreateRGBSurface(0, 160, 144, 32,
                                                            0, 0, 0, 0);

    if (ctx->dut->px_valid_out &&
        ctx->dut->x_pos_out < 160 &&
        ctx->dut->y_pos_out < 144) {

        // Pixel is valid and at a reasonable position
        uint32_t* px_pointer = (uint32_t*)temp_surface->pixels + 
                              (ctx->dut->y_pos_out * 160 + ctx->dut->x_pos_out);

        *px_pointer = palette[ctx->dut->color_out];

        if (ctx->dut->x_pos_out == 159 &&
            ctx->dut->y_pos_out == 143) {

            SDL_LockMutex(g_lcd_display.renderer_lock);

            SDL_UnlockMutex(g_lcd_display.renderer_lock);
            SDL_BlitSurface(temp_surface, nullptr,
                            g_lcd_display.draw_surface, nullptr);
            SDL_LockMutex(g_lcd_display.signal_lock);
            g_lcd_display.have_update = true;
            SDL_CondSignal(g_lcd_display.signal);
            SDL_UnlockMutex(g_lcd_display.signal_lock);
        }
    }

}

int render_thread(void* ptr) {

    printf("Starting thred\n");

    static int count = 0;

    while (true)
    {
        SDL_LockMutex(g_lcd_display.signal_lock);
        while (g_lcd_display.should_quit == false &&
               g_lcd_display.have_update == false)
        {
            SDL_CondWait(g_lcd_display.signal,
                         g_lcd_display.signal_lock);
        }
        SDL_UnlockMutex(g_lcd_display.signal_lock);

        if (g_lcd_display.should_quit) {
            break;
        }

        SDL_Surface* lcd_surface = SDL_GetWindowSurface(g_lcd_display.window);

        SDL_LockMutex(g_lcd_display.renderer_lock);
        SDL_BlitScaled(g_lcd_display.draw_surface, nullptr,
                       lcd_surface, nullptr);
        SDL_UnlockMutex(g_lcd_display.renderer_lock);

        SDL_UpdateWindowSurface(g_lcd_display.window);
        g_lcd_display.have_update = false;

    }

    return 0;
}


int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    ::testing::InitGoogleTest(&argc, argv);

    SDL_Init(SDL_INIT_VIDEO);

    g_lcd_display.window = SDL_CreateWindow("gb", 0, 0,
                                        160 * 4, 144 * 4, SDL_WINDOW_OPENGL);
    assert(g_lcd_display.window != nullptr);
    
    g_lcd_display.renderer_lock = SDL_CreateMutex();
    g_lcd_display.should_quit = false;
    g_lcd_display.have_update = false;
    g_lcd_display.draw_surface = SDL_CreateRGBSurface(0, 160, 144, 32,
                                                      0, 0, 0, 0);

    SDL_Thread* display_thread = SDL_CreateThread(render_thread, "SDL Render", nullptr);

    int res = RUN_ALL_TESTS();

    printf("Waiting for Enter...");
    fflush(stdout);
    getchar();

    SDL_LockMutex(g_lcd_display.signal_lock);
    g_lcd_display.should_quit = true;
    SDL_CondSignal(g_lcd_display.signal);
    SDL_UnlockMutex(g_lcd_display.signal_lock);

    SDL_WaitThread(display_thread, nullptr);

    SDL_DestroyWindow(g_lcd_display.window);

    SDL_Quit();

    return res;
}
