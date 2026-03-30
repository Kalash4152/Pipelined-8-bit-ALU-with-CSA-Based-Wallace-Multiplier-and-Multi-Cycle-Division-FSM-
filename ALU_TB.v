`timescale 1ns/1ps

module tb_alu;

reg clk;
reg rst;
reg [7:0] A, B, opcode;
reg vin;

wire [15:0] Y;
wire valid_out;

wire z, c, si, v;

// Instantiate DUT
ALU dut (
    .clk(clk),
    .rst(rst),
    .rs_a(A),
    .rs_b(B),
    .rs_opcode(opcode),
    .vin(vin),
    .Y(Y),
    .valid_out(valid_out),
    .flg_z(z),
    .flg_c(c),
    .flg_si(si),
    .flg_v(v)
);

////////////////////////////////////////////////////////////
// CLOCK
////////////////////////////////////////////////////////////
initial clk = 0;
always #5 clk = ~clk;  // 10ns period

////////////////////////////////////////////////////////////
// TASK: APPLY INPUT
////////////////////////////////////////////////////////////
task apply_input;
    input [7:0] a, b, op;
    begin
        @(posedge clk);
        A <= a;
        B <= b;
        opcode <= op;
        vin <= 1;
        
        @(posedge clk);
        vin <= 0;
    end
endtask

////////////////////////////////////////////////////////////
// MONITOR OUTPUT
////////////////////////////////////////////////////////////
always @(posedge clk) begin
    if (valid_out) begin
        $display("TIME=%0t | RESULT=%0d | Z=%b C=%b S=%b V=%b",
                 $time, Y, z, c, si, v);
    end
end

////////////////////////////////////////////////////////////
// TEST SEQUENCE
////////////////////////////////////////////////////////////
initial begin
    $display("==== ALU TEST START ====");

    // INIT
    rst = 1;
    vin = 0;
    A = 0;
    B = 0;
    opcode = 0;

    #20;
    rst = 0;

    // ADD
    apply_input(10, 5, 8'd0);

    // SUB
    apply_input(20, 8, 8'd1);

    // AND
    apply_input(12, 10, 8'd2);

    // OR
    apply_input(12, 10, 8'd3);

    // XOR
    apply_input(12, 10, 8'd4);

    // SHIFT LEFT
    apply_input(8, 0, 8'd5);

    // SHIFT RIGHT
    apply_input(8, 0, 8'd6);

    // MUL (pipeline latency visible)
    apply_input(6, 7, 8'd7);

    // DIV (multi-cycle latency visible)
    apply_input(50, 5, 8'd8);

    // MORE TESTS
    apply_input(0, 0, 8'd0);   // zero test
    apply_input(255, 1, 8'd0); // overflow test

    #200;

    $display("==== TEST COMPLETE ====");
    $finish;
end

endmodule
