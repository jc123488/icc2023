module LASER (
input CLK,
input RST,
input [3:0] X,
input [3:0] Y,
output reg [3:0] C1X,
output reg [3:0] C1Y,
output reg [3:0] C2X,
output reg [3:0] C2Y,
output reg DONE);

reg [3:0] X_in [0:39];
reg [3:0] Y_in [0:39];
integer i;

reg [1:0] state_cs, state_ns;
parameter IDLE = 2'd0, 
          INPUT = 2'd1,
          CNT = 2'd2,
          OUTPUT = 2'd3;

reg [5:0] cnt_40;

always @(posedge CLK or posedge RST) begin
    if(RST)
        state_cs <= IDLE;
    else
        state_cs <= state_ns;
end

always @(*) begin
    case (state_cs)
        IDLE:
            state_ns = INPUT; 
        INPUT:
            state_ns = (cnt_40 == 6'd39) ? INPUT : CNT;
        default: 
            state_ns = IDLE;
    endcase
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_40 <= 6'd0;
    else if(state_cs == INPUT)
        cnt_40 <= cnt_40 + 6'd1;
    else 
        cnt_40 <= 6'd0;
end

always @(posedge CLK) begin
    if(state_cs == IDLE || state_cs == OUTPUT)begin
        for (i = 0;i<40 ; i=i+1) begin
            X_in[i] <= 4'd0;
            Y_in[i] <= 4'd0;
        end
    end
    else if(state_cs == INPUT)begin
        X_in[cnt_40] <= X;
        Y_in[cnt_40] <= Y;
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        DONE <= 1'd0;
    else if(state_cs == OUTPUT)
        DONE <= 1'd1;
    else 
        DONE <= 1'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
    else if(state_cs == OUTPUT)begin

    end
    else begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
end

endmodule


