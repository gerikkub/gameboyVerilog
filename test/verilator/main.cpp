
#include <cstdio>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#include <verilated.h>
#include <verilated_vcd_c.h>

#include "obj_dir/Vgb_interconnect.h"

#include "gtest/gtest.h"

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

bool run_test(std::string test_filename, uint64_t timeout, std::string log_name);

TEST(INDIVIDUAL, 01) {
    bool res = run_test("test_roms/cpu_instrs/individual/01/01-special.gb", 11000000, "");
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

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    ::testing::InitGoogleTest(&argc, argv);

    return RUN_ALL_TESTS();
}


bool run_test(std::string test_filename, uint64_t timeout, std::string log_name) {

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
        .contextp = contextp
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

        if (count % 1000000 == 0) {
            //printf("%lu\n", count);
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