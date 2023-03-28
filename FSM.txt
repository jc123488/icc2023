module FSM();

reg [2:0] state_cs, state_ns;
parameter IDLE = 3'd0;

always @(posedge clk or posedge rst) begin
    if(rst)
        state_cs <= IDLE;
    else
        state_cs <= state_ns;
end

always @(*) begin
    case (state_cs)
        IDLE:
            state_ns = ; 
        default: 
            state_ns = IDLE;
    endcase
end

endmodule