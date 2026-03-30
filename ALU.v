
// ===================== ALU =====================
module ALU(
    input clk,
    input rst,
    input [7:0] rs_a,
    input [7:0] rs_b,
    input [7:0] rs_opcode,
    input vin,

    output reg [15:0] Y,
    output reg valid_out,
    output reg flg_z,
    output reg flg_c,
    output reg flg_si,
    output reg flg_v
);

// ---------- STAGE 1 ----------
reg [7:0] L1_A, L1_B, L1_opcode;
reg v1;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        L1_A <= 0; L1_B <= 0; L1_opcode <= 0; v1 <= 0;
    end else begin
        L1_A <= rs_a;
        L1_B <= rs_b;
        L1_opcode <= rs_opcode;
        v1 <= vin;
    end
end

// ---------- STAGE 2 ----------
reg [7:0] L2_opcode;
reg [7:0] fast_res;
reg fast_c, fast_v;
reg v2;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        L2_opcode <= 0; fast_res <= 0;
        fast_c <= 0; fast_v <= 0; v2 <= 0;
    end else begin
        L2_opcode <= L1_opcode;
        v2 <= v1;

        case (L1_opcode)
            8'd0: begin
                {fast_c, fast_res} <= L1_A + L1_B;
                fast_v <= (L1_A[7]&L1_B[7]&~fast_res[7]) |
                          (~L1_A[7]&~L1_B[7]&fast_res[7]);
            end

            8'd1: begin
                fast_res <= L1_A - L1_B;
                fast_c <= (L1_A < L1_B);
                fast_v <= (L1_A[7]&~L1_B[7]&~fast_res[7]) |
                          (~L1_A[7]&L1_B[7]&fast_res[7]);
            end

            8'd2: fast_res <= L1_A & L1_B;
            8'd3: fast_res <= L1_A | L1_B;
            8'd4: fast_res <= L1_A ^ L1_B;

            8'd5: begin fast_res <= L1_A << 1; fast_c <= L1_A[7]; end
            8'd6: begin fast_res <= L1_A >> 1; fast_c <= L1_A[0]; end

            default: begin fast_res <= 0; fast_c <= 0; fast_v <= 0; end
        endcase
    end
end

// ---------- MUL ----------
wire [15:0] mul_out;
wire mul_valid;

wallace_mul mul_u (
    .clk(clk),
    .rst(rst),
    .valid_in(v1 && (L1_opcode == 8'd7)),
    .A(L1_A),
    .B(L1_B),
    .Y(mul_out),
    .valid_out(mul_valid)
);

// ---------- DIV ----------
wire [7:0] q, r;
wire div_done;

div_fsm div_u (
    .clk(clk),
    .rst(rst),
    .start(v1 && (L1_opcode == 8'd8)),
    .dividend(L1_A),
    .divisor(L1_B),
    .quotient(q),
    .remainder(r),
    .done(div_done)
);

wire [15:0] div_out = {r, q};

// ---------- STAGE 3 ----------
reg [15:0] Y_next;
reg C_next, V_next;
reg valid_next;

always @(*) begin
    case (L2_opcode)
        8'd0,8'd1,8'd2,8'd3,8'd4,8'd5,8'd6: begin
            Y_next = {8'd0, fast_res};
            C_next = fast_c;
            V_next = fast_v;
            valid_next = v2;
        end
        8'd7: begin
            Y_next = mul_out;
            C_next = 0; V_next = 0;
            valid_next = mul_valid;
        end
        8'd8: begin
            Y_next = div_out;
            C_next = 0; V_next = 0;
            valid_next = div_done;
        end
        default: begin
            Y_next = 0;
            C_next = 0; V_next = 0;
            valid_next = 0;
        end
    endcase
end

// ---------- STAGE 4 ----------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Y <= 0; valid_out <= 0;
        flg_z <= 0; flg_c <= 0; flg_si <= 0; flg_v <= 0;
    end else begin
        Y <= Y_next;
        valid_out <= valid_next;

        flg_z <= (Y_next == 0);
        flg_si <= Y_next[15];

        case (L2_opcode)
            8'd0,8'd1: begin flg_c <= C_next; flg_v <= V_next; end
            default: begin flg_c <= 0; flg_v <= 0; end
        endcase
    end
end

endmodule

// ================= MUL =================
module wallace_mul(
    input clk, input rst, input valid_in,
    input [7:0] A, input [7:0] B,
    output reg [15:0] Y,
    output reg valid_out
);

reg [15:0] pp[7:0];
reg [15:0] s, c, temp_s;
integer i, k;
reg v1, v2, v3;

// Stage 1
always @(posedge clk or posedge rst) begin
    if (rst) begin
        v1 <= 0;
        for (i=0;i<8;i=i+1) pp[i] <= 0;
    end else begin
        v1 <= valid_in;
        for (i=0;i<8;i=i+1)
            pp[i] <= (A & {8{B[i]}}) << i;
    end
end

// Stage 2
always @(posedge clk or posedge rst) begin
    if (rst) begin
        s <= 0; c <= 0; v2 <= 0;
    end else begin
        v2 <= v1;
        s = pp[0]; c = 0;

        for (k=1;k<8;k=k+1) begin
            temp_s = s ^ c ^ pp[k];
            c = ((s & c) | (c & pp[k]) | (s & pp[k])) << 1;
            s = temp_s;
        end

        s <= s;
        c <= c;
    end
end

// Stage 3
always @(posedge clk or posedge rst) begin
    if (rst) begin
        Y <= 0; valid_out <= 0; v3 <= 0;
    end else begin
        v3 <= v2;
        Y <= s + c;
        valid_out <= v3;
    end
end

endmodule

// ================= DIV =================
module div_fsm(
    input clk, input rst, input start,
    input [7:0] dividend, input [7:0] divisor,
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg done
);

reg [15:0] A;
reg [7:0] M;
reg [3:0] count;
reg busy;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        quotient <= 0; remainder <= 0;
        done <= 0; busy <= 0;
    end else begin
        if (start && !busy) begin
            A <= {8'd0, dividend};
            M <= divisor;
            count <= 8;
            busy <= 1;
            done <= 0;
        end
        else if (busy) begin
            A <= A << 1;
            A[15:8] <= A[15:8] - M;

            if (A[15]) begin
                A[15:8] <= A[15:8] + M;
                A[0] <= 0;
            end else begin
                A[0] <= 1;
            end

            count <= count - 1;

            if (count == 0) begin
                quotient <= A[7:0];
                remainder <= A[15:8];
                done <= 1;
                busy <= 0;
            end
        end else begin
            done <= 0;
        end
    end
end

endmodule
