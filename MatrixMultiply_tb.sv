`timescale 1ns/1ps
`default_nettype none

module tb_top;

  logic clk;
  logic reset_n;
  logic en1, en2, en3;
  logic [1:0] error;
  logic out1, out2;

  // 100 Hz Clock Generator (simulated as 10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // DUT Instantiation
  top dut (
    .hz100   (clk),
    .reset_n (reset_n),
    .en1     (en1),
    .en2     (en2),
    .en3     (en3),
    .error   (error),
    .out1    (out1),
    .out2    (out2)
  );

  initial begin
    $dumpfile("quantum_fsm.vcd");
    $dumpvars(0, tb_top);

    $display("================================================================");
    $display("          QUANTUM CIRCUIT FSM STATE TESTBENCH                   ");
    $display("================================================================");

    // Initial reset
    reset_n = 1'b0;
    en1     = 1'b0;
    en2     = 1'b0;
    en3     = 1'b0;
    #15;
    reset_n = 1'b1;
    $display("[T=%0t] Reset released. Initial q1=%b, q2=%b", $time, dut.q1, dut.q2);

    // Run full cycle: No Pauli-Z gates enabled
    $display("\n--- CYCLE 1: Idle Run (Enables 000) ---");
    repeat (8) @(posedge clk);

    // Run cycle: Enable Z-gates at counter step 1 (en1, en3)
    $display("\n--- CYCLE 2: Phase Correction on Q1 & Q2 (en1=1, en3=1) ---");
    @(negedge clk);
    en1 = 1'b1;
    en3 = 1'b1;
    repeat (8) @(posedge clk);
    en1 = 1'b0;
    en3 = 1'b0;

    // Run cycle: Enable Z-gates at counter step 3 (en2)
    $display("\n--- CYCLE 3: Mid-State Flip (en2=1) ---");
    @(negedge clk);
    en2 = 1'b1;
    repeat (8) @(posedge clk);
    en2 = 1'b0;

    $display("\n================================================================");
    $display("                 SIMULATION COMPLETE                            ");
    $display("================================================================");
    $finish;
  end

  // Monitor internal register states on each step
  always @(posedge clk) begin
    if (reset_n) begin
      $display("[T=%5t] step=%0d | q1=%b q2=%b | h1=%b z1=%b | error=%b",
               $time, dut.counter, dut.q1, dut.q2, dut.h1, dut.z1, error);
    end
  end

endmodule