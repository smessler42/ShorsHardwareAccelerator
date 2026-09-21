`timescale 1ns/1ps
`default_nettype none

module tb_quantum_error_pipeline;

  // -------------------------------------------------------------
  // Clock & Control Signals
  // -------------------------------------------------------------
  logic clk;
  logic rst_n;
  integer test_idx;

  // 100 Hz Clock Generator (simulated at 10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // -------------------------------------------------------------
  // Qubit State Vectors: [2][1]
  // -------------------------------------------------------------
  // Basis state |0> = [1, 0]^T
  localparam logic signed [1:0] STATE_ZERO [2][1] = '{
    '{2'sd1},
    '{2'sd0}
  };

  // Basis state |1> = [0, 1]^T
  localparam logic signed [1:0] STATE_ONE [2][1] = '{
    '{2'sd0},
    '{2'sd1}
  };

  // Original encoded cluster (qubits 1, 2, 3)
  logic signed [1:0] q_orig1 [2][1];
  logic signed [1:0] q_orig2 [2][1];
  logic signed [1:0] q_orig3 [2][1];

  // Qubits after error injection (corrupted state)
  logic signed [1:0] q_corrupt1 [2][1];
  logic signed [1:0] q_corrupt2 [2][1];
  logic signed [1:0] q_corrupt3 [2][1];

  // Error stimulus and syndrome detection output
  logic [1:0] injected_error;
  logic [1:0] detected_error;

  // -------------------------------------------------------------
  // Device Under Test (DUT) 1: Error Injection Unit
  // -------------------------------------------------------------
  bit_error u_injector (
    .error (injected_error),
    .in1   (q_orig1),
    .in2   (q_orig2),
    .in3   (q_orig3),
    .out1  (q_corrupt1),
    .out2  (q_corrupt2),
    .out3  (q_corrupt3)
  );

  // -------------------------------------------------------------
  // Device Under Test (DUT) 2: Syndrome Extraction & Detector
  // -------------------------------------------------------------
  bit_flip_detect u_detector (
    .hz100 (clk),
    .rst_n (rst_n),
    .q1    (q_corrupt1),
    .q2    (q_corrupt2),
    .q3    (q_corrupt3),
    .error (detected_error)
  );

  // -------------------------------------------------------------
  // Task: Run Syndrome Detection Cycle
  // -------------------------------------------------------------
  task automatic run_detection_cycle(
    input  logic [1:0] err_target,
    input  string      test_name
  );
    begin
      $display("\n------------------------------------------------------------");
      $display(" Running %s: Injecting Error Code = 2'b%b", test_name, err_target);
      $display("------------------------------------------------------------");

      // 1. Reset the detector state machine
      @(negedge clk);
      rst_n = 1'b0;
      injected_error = err_target;
      @(negedge clk);
      rst_n = 1'b1;

      // 2. Wait for FSM to step through states 0 -> 5
      // (counter cycles: 0: Hadamard, 1: CNOT-1, 2: CNOT-2, 3: CNOT-3, 4: Hadamard, 5: Readout)
      repeat (7) @(posedge clk);

      // 3. Inspect corrupted state vector amplitudes
      $display("  State Vectors after injection:");
      $display("    Q1: [%0d, %0d] | Q2: [%0d, %0d] | Q3: [%0d, %0d]",
               q_corrupt1[0][0], q_corrupt1[1][0],
               q_corrupt2[0][0], q_corrupt2[1][0],
               q_corrupt3[0][0], q_corrupt3[1][0]);

      // 4. Evaluate Detection Result
      $display("  Syndrome Readout : 2'b%b", detected_error);
      case (err_target)
        2'b00: $display("  Target Location  : No Error Expected");
        2'b01: $display("  Target Location  : Qubit 1 Flown/Flipped");
        2'b10: $display("  Target Location  : Qubit 2 Flown/Flipped");
        2'b11: $display("  Target Location  : Qubit 3 Flown/Flipped");
      endcase

      $display("  Detected Location: %s",
               (detected_error == 2'b00) ? "No Error Detected" :
               (detected_error == 2'b01) ? "Fault on Qubit 1" :
               (detected_error == 2'b10) ? "Fault on Qubit 2" :
               (detected_error == 2'b11) ? "Fault on Qubit 3" : "Unknown Syndrome");
    end
  endtask

  // -------------------------------------------------------------
  // Testbench Stimulus Execution
  // -------------------------------------------------------------
  initial begin
    $dumpfile("quantum_error_pipeline.vcd");
    $dumpvars(0, tb_quantum_error_pipeline);

    $display("================================================================");
    $display("       QUANTUM ERROR INJECTION & DETECTION TEST HARNESS        ");
    $display("================================================================");

    // Initialize inputs: All 3 qubits start in basis state |0>
    q_orig1 = STATE_ZERO;
    q_orig2 = STATE_ZERO;
    q_orig3 = STATE_ZERO;
    injected_error = 2'b00;
    rst_n = 1'b0;
    #15;
    rst_n = 1'b1;

    // Test 1: No error injected (control run)
    run_detection_cycle(2'b00, "TEST 1: Ideal State (No Error)");

    // Test 2: Bit flip on Qubit 1 (in1)
    run_detection_cycle(2'b01, "TEST 2: Bit Flip on Qubit 1");

    // Test 3: Bit flip on Qubit 2 (in2)
    run_detection_cycle(2'b10, "TEST 3: Bit Flip on Qubit 2");

    // Test 4: Bit flip on Qubit 3 (in3)
    run_detection_cycle(2'b11, "TEST 4: Bit Flip on Qubit 3");

    // Test 5: Re-test with initial state |1> (|111> cluster)
    $display("\n================================================================");
    $display("       RE-TESTING WITH BASIS STATE |1> (|111> Cluster)         ");
    $display("================================================================");
    q_orig1 = STATE_ONE;
    q_orig2 = STATE_ONE;
    q_orig3 = STATE_ONE;

    run_detection_cycle(2'b01, "TEST 5: Bit Flip on Qubit 1 in |111>");
    run_detection_cycle(2'b10, "TEST 6: Bit Flip on Qubit 2 in |111>");

    $display("\n================================================================");
    $display("                    ALL TESTS COMPLETED                         ");
    $display("================================================================");
    $finish;
  end

endmodule