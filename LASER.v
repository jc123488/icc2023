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

reg [39:0] in_C1, in_C2;
reg [4:0] in_cnt1, in_cnt2;

reg [5:0] left_down_cnt, left_up_cnt, right_down_cnt, right_up_cnt;

wire is_left_down, is_left_up, is_right_down, is_right_up;

assign is_left_up = (X < 4'd8 && Y < 4'd8) ? 1'd1 : 1'd0;
assign is_left_down = (X < 4'd8 && Y > 4'd7) ? 1'd1 : 1'd0;
assign is_right_up = (X > 4'd7 && Y < 4'd8) ? 1'd1 : 1'd0;
assign is_right_down = (X > 4'd7 && Y > 4'd7) ? 1'd1 : 1'd0;

reg [2:0] state_cs, state_ns;
parameter IDLE = 3'd0, 
          INPUT = 3'd1,
          COMP = 3'd2,
          CNT1 = 3'd3,
          CNT2 = 3'd4,
          OPT = 3'd5,
          OUTPUT = 3'd6;

reg [5:0] cnt_40;
reg [6:0] cnt_64;
reg [2:0] max,sec,cnt_7;
reg [5:0] max_v,sec_v;

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
            state_ns = (cnt_40 == 6'd39) ? COMP : INPUT;
        COMP:
            state_ns = (cnt_7 == 3'd2) ? CNT1 : COMP;
        CNT1:
            state_ns = (cnt_64 == 7'd63) ? CNT2 : CNT1;
        CNT2:
        // CNT1:

        // CNT2:

        // OPT:

        // OUTPUT:
            // state_ns = IDLE;
        default: 
            state_ns = IDLE;
    endcase
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_40 <= 6'd0;
    else if(state_cs == INPUT || state_cs == CNT1)
        if(cnt_40==6'd39)
            cnt_40<=6'd0;
        else
            cnt_40 <= cnt_40 + 6'd1;
    else 
        cnt_40 <= 6'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_64 <=7'd0;
    else if(state_cs == CNT1 && cnt_40==6'd39)
        cnt_64 <=cnt_64+1;
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
    if(RST)begin
        left_down_cnt <= 6'd0;
        left_up_cnt <= 6'd0;
        right_down_cnt <= 6'd0;
        right_up_cnt <= 6'd0;
    end
    else if(state_cs == INPUT)begin
        if(is_left_up)begin
            left_up_cnt <= left_up_cnt + 6'd1;
        end
        else if(is_left_down)begin
            left_down_cnt <= left_down_cnt + 6'd1;
        end
        else if(is_right_up)begin
            right_up_cnt <= right_up_cnt + 6'd1;
        end
        else begin
            right_down_cnt <= right_down_cnt + 6'd1;
        end
    end
    else if(state_cs == OUTPUT)begin
        left_down_cnt <= 6'd0;
        left_up_cnt <= 6'd0;
        right_down_cnt <= 6'd0;
        right_up_cnt <= 6'd0;
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_7<= 3'd0;
    else if(state_cs == COMP)begin
        cnt_7<=cnt_7+1;
    end
end

//max,sec
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        max<= 2'd0;
    end
    else if(state_cs == COMP)begin
        case (cnt_7)
            3'd0: begin
                if (right_up_cnt>left_up_cnt) 
                    max<= 2'd1;
            end
            3'd1: begin
                if(left_down_cnt>max_v) 
                    max<= 2'd2;
            end
            3'd2: begin
                if(right_down_cnt>max_v)
                    max<= 2'd3;
        end
        endcase
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        sec<= 2'd1;
    end
    else if(state_cs == COMP)begin
        case (cnt_7)
            3'd0: begin
                if (right_up_cnt>left_up_cnt) 
                    sec<= 2'd0;
            end
            3'd1: begin
                if(left_down_cnt>max_v) 
                    sec<= max;
            end
            3'd2: begin
                if(right_down_cnt>max_v)
                    sec<= max;
        end
        endcase
    end
end


always @(posedge CLK or posedge RST) begin
    if(RST)
        max_v<= 6'd0;
    else if(state_cs == COMP)begin
        case (cnt_7)
            3'd0: begin
                if (right_up_cnt>left_up_cnt) 
                    max_v<= right_up_cnt;
            end
            3'd1: begin
                if(left_down_cnt>max_v)
                    max_v<= left_down_cnt;
            end
            3'd2: begin
                if(right_down_cnt>max_v)
                    max_v<= right_down_cnt;
            end
        endcase
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        DONE <= 1'd1;
    else if(state_cs == OUTPUT)
        DONE <= 1'd1;
    else 
        DONE <= 1'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
    end
    else if(state_cs == CNT1)begin
        if(cnt_64==7'd0)

    end
    // else if()begin

    // end
    else begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
    else begin
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
end


endmodule


