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

reg [39:0] in_C1, in_C2,in_C1_max, in_C2_max;
reg [4:0] in_cnt1, in_cnt2,in_cnt1_max, in_cnt2_max;

reg [5:0] left_down_cnt, left_up_cnt, right_down_cnt, right_up_cnt;

wire is_left_down, is_left_up, is_right_down, is_right_up;
wire [3:0]x_mis,y_mis,mis_b,mis_s;


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
          OPT1 = 3'd5,
          OPT2 = 3'd6,
          OUTPUT = 3'd7;

reg [5:0] cnt_40;
reg [6:0] cnt_64;
reg [2:0] max,sec,cnt_7,cnt_6;
reg [5:0] max_v;

reg [3:0] circle_x, circle_y;

reg [3:0] max_circle1_x[0:9];
reg [3:0] max_circle1_y[0:9];
reg [3:0] max_circle2_x[0:9];
reg [3:0] max_circle2_y[0:9];
reg [3:0] cnt_max, cnt_opt;
reg cd_line;

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
            state_ns = (cnt_64 == 7'd35) ? OPT1 : CNT2;
        OPT1:
            state_ns = (cnt_40 == 6'd39) ? OPT2 : OPT1;
        OPT2:
            state_ns = (cnt_40 == 6'd39) ? (cnt_opt == 4'd9) ? OUTPUT : OPT1 : OPT2;
        OUTPUT:
            state_ns = IDLE;
        default: 
            state_ns = IDLE;
    endcase
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_opt <= 4'd0;
    else if(state_cs == OPT2)
        if(cnt_40 == 6'd39)
            cnt_opt <= cnt_opt + 4'd1;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_40 <= 6'd0;
    else if(state_cs == INPUT || state_cs == CNT1 || state_cs == CNT2)
        if(cnt_40==6'd39)
            cnt_40<=6'd0;
        else
            cnt_40 <= cnt_40 + 6'd1;
    else if(state_cs == OPT1)
        if(cnt_40==6'd39)
            cnt_40<=6'd0;
        else if(max_circle1_x[cnt_opt] == C1X && max_circle1_y[cnt_opt] == C1Y)
            cnt_40 <= 6'd39;
        else
            cnt_40 <= cnt_40 + 6'd1;
    else if(state_cs == OPT2)
        if(cnt_40==6'd39)
            cnt_40<=6'd0;
        else if(max_circle2_x[cnt_opt] == C2X && max_circle2_y[cnt_opt] == C2Y)
            cnt_40 <= 6'd39;
        else
            cnt_40 <= cnt_40 + 6'd1;
    else 
        cnt_40 <= 6'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_6 <= 3'd0;
    else if(state_cs == CNT2)
        if(cnt_6==3'd5)
            cnt_6<=6'd0;
        else
            cnt_6 <= cnt_6 + 3'd1;
    else 
        cnt_6 <= 3'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_64 <=7'd0;
    else if(state_cs == CNT1 && cnt_40 == 6'd39)
        cnt_64 <= cnt_64 + 1;
    else if(state_cs == CNT2 && cnt_40 == 6'd39)
        cnt_64 <= cnt_64 + 1;
end

always @(*) begin
    if(state_cs == CNT1 && cnt_64[2:0]==3'd7)
        cd_line=1;
    else if(state_cs == CNT2 && cnt_6==3'd5)
        cd_line=1;
    else    
        cd_line=0;
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
        else if(is_right_down)begin
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
//max_circle1_x
// always @(posedge CLK or posedge RST) begin
//      if(RST)
//         in_C1<=40'd0;
//     else if(state_cs == CNT1
// end

//in_C1_max
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        in_C1_max<=40'd0;
        in_cnt1_max<=5'd0;
    end
    else if(state_cs == CNT1 && cnt_40==6'd39 && in_cnt1_max<in_cnt1)begin
        in_C1_max<=in_C1;
        in_cnt1_max<=in_cnt1;
    end
end

//in_C2_max
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        in_C2_max<=40'd0;
        in_cnt2_max<=5'd0;
    end
    else if(state_cs == CNT2 && cnt_40==6'd39 && in_cnt2_max<in_cnt2)begin
        in_C2_max<=in_C2;
        in_cnt2_max<=in_cnt2;
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
    else if(state_cs == CNT1)begin
        if(cnt_40==6'd39 && in_cnt1_max<in_cnt1)begin
            C1X <= circle_x;
            C1Y <= circle_y;
        end
    end
    else if(state_cs == CNT2)begin
        if(cnt_40==6'd39 && in_cnt2_max<in_cnt2)begin
            C2X <= circle_x;
            C2Y <= circle_y;
        end
    end
    else if(state_cs == OPT1)begin
        C1X <= circle_x;
        C1Y <= circle_y;
    end
    else if(state_cs == OPT2)begin
        C2X <= circle_x;
        C2Y <= circle_y;
    end
    else begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
end

//circle_x circle_y
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        circle_x <= 4'd0;
        circle_y <= 4'd0;
    end
    else if(state_cs == CNT1) begin
        if(cnt_64==7'd0)   // start point
            case (max)
                2'd0:begin
                    circle_x <= 4'd0;
                    circle_y <= 4'd0;
                end
                2'd1:begin
                    circle_x <= 4'd15;
                    circle_y <= 4'd0;
                end
                2'd2:begin
                    circle_x <= 4'd0;
                    circle_y <= 4'd15;
                end
                2'd3:begin
                    circle_x <= 4'd15;
                    circle_y <= 4'd15;
                end
            endcase
        else if(cd_line && cnt_40==6'd39)begin
            case (max)
                2'd0:begin
                    circle_x <= 4'd0;
                    circle_y <= circle_y+1;
                end
                2'd1:begin
                    circle_x <= 4'd15;
                    circle_y <= circle_y+1;
                end
                2'd2:begin
                    circle_x <= 4'd0;
                    circle_y <= circle_y-1;
                end
                2'd3:begin
                    circle_x <= 4'd15;
                    circle_y <= circle_y-1;
                end
            endcase
        end
        else if(cnt_40==6'd39)begin
            case (max)  //next point
                2'd0:begin
                    circle_x <= circle_x+1;
                end
                2'd1:begin
                    circle_x <=circle_x-1;
                end
                2'd2:begin
                    circle_x <= circle_x+1;
                end
                2'd3:begin
                    circle_x <=circle_x-1;
                end
            endcase
        end
    end
    else if(state_cs == CNT2) begin
        if(cnt_64==7'd0 )begin
            case (sec)
                2'd0:begin
                    circle_x <= 4'd2;
                    circle_y <= 4'd2;
                end
                2'd1:begin
                    circle_x <= 4'd13;
                    circle_y <= 4'd2;
                end
                2'd2:begin
                    circle_x <= 4'd2;
                    circle_y <= 4'd13;
                end
                2'd3:begin
                    circle_x <= 4'd13;
                    circle_y <= 4'd13;
                end
            endcase
        end
        else if(cd_line && cnt_40==6'd39)begin
            case (sec)
                2'd0:begin
                    circle_x <= 4'd2;
                    circle_y <= circle_y+1;
                end
                2'd1:begin
                    circle_x <= 4'd13;
                    circle_y <= circle_y+1;
                end
                2'd2:begin
                    circle_x <= 4'd2;
                    circle_y <= circle_y-1;
                end
                2'd3:begin
                    circle_x <= 4'd13;
                    circle_y <= circle_y-1;
                end
            endcase
        end
        else if( cnt_40==6'd39)begin
            case (sec)  //next point
                2'd0:begin
                    circle_x <= circle_x+1;
                end
                2'd1:begin
                    circle_x <=circle_x-1;
                end
                2'd2:begin
                    circle_x <= circle_x+1;
                end
                2'd3:begin
                    circle_x <=circle_x-1;
                end
            endcase
        end
    end
    else if(state_cs == OPT1)begin
        circle_x <= max_circle1_x[cnt_opt];
        circle_y <= max_circle1_y[cnt_opt];
    end 
    else if(state_cs == OPT2)begin
        circle_x <= max_circle2_x[cnt_opt];
        circle_y <= max_circle2_y[cnt_opt];
    end 
end

assign x_mis=(circle_x > X_in[cnt_40])? circle_x - X_in[cnt_40]: X_in[cnt_40]-circle_x;
assign y_mis=(circle_y > Y_in[cnt_40])? circle_y - Y_in[cnt_40]: Y_in[cnt_40]-circle_y;
assign mis_b=(x_mis>y_mis)?x_mis:y_mis;
assign mis_s=(x_mis<y_mis)?y_mis:x_mis;

//determine dot in the circle
always @(posedge CLK or posedge RST) begin
    if(state_cs == CNT1)begin
        if(mis_b==4 && mis_s==0)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
        else if(mis_b==3 && mis_s<3)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
        else if(mis_b==2 && mis_s<4)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
        else if(mis_b==1 && mis_s<4)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
    end
end

always @(posedge CLK or posedge RST) begin
    if(state_cs == CNT2 && ~in_C1[cnt_40])begin
        if(mis_b==4 && mis_s==0)begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
        else if(mis_b==3 && mis_s<3)begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
        else if(mis_b==2 && mis_s<4)begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
        else if(mis_b==1 && mis_s<4)begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
    end
end

// always @(posedge CLK or posedge RST) begin
//     if(RST)
//         dot_in <= 6'd0;
//     else if 
// end

endmodule


