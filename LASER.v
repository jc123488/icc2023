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

wire is_left_down, is_left_up, is_right_down, is_right_up,already_in_C1;
wire [3:0]x_mis,y_mis,mis_b,mis_s;
reg [4:0] in_cnt2_r;

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
reg [5:0] max_v,sec_v;

reg [3:0] circle_x, circle_y;

reg [3:0] max_circle1_x[0:18];
reg [3:0] max_circle1_y[0:18];
reg [3:0] max_circle2_x;
reg [3:0] max_circle2_y;
reg [4:0] cnt_max, cnt_opt;
reg cd_line;
reg [4:0] cnt_24;
assign already_in_C1=in_C1_max[cnt_40];//cnt_40

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
            state_ns = (cnt_64 == 7'd63 && cnt_40 ==6'd39) ? CNT2 : CNT1;
        CNT2:
            state_ns = (cnt_64 == 7'd19 && cnt_40 ==6'd39) ? OUTPUT : CNT2;
        OUTPUT:
            state_ns = IDLE;
        default: 
            state_ns = IDLE;
    endcase
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_40 <= 6'd0;
    else if(state_cs == INPUT || state_cs == CNT1 || state_cs == CNT2)
        if(cnt_40==6'd39)
            cnt_40<=6'd0;
        else
            cnt_40 <= cnt_40 + 6'd1;
    else 
        cnt_40 <= 6'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_6 <= 3'd0;
    else if(state_cs == CNT2)begin
        if(cnt_6==3'd5 && cnt_40 == 6'd39)
            cnt_6<=6'd0;
        else if(cnt_40 == 6'd39)
            cnt_6 <= cnt_6 + 3'd1;
    end
    else 
        cnt_6 <= 3'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        cnt_64 <=7'd0;
    else if(state_cs == CNT1 && cnt_40 == 6'd39)begin
        if(cnt_64==6'd63)
            cnt_64 <=7'd0;
        else
            cnt_64 <= cnt_64 + 1;
    end
    else if(state_cs == CNT2 && cnt_40 == 6'd39 && cnt_24 == 23)
        cnt_64 <= cnt_64 + 1;
	else if(state_cs == OUTPUT)
		cnt_64 <=7'd0;
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
	else if(state_cs == OUTPUT)
		cnt_7<= 3'd0;
end

//max,sec
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        max<= 2'd0;
    end
    else if(state_cs == COMP)begin
        case (cnt_7)
            3'd0: begin
                if (right_up_cnt>=left_up_cnt) 
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
	else if(state_cs == OUTPUT)
		max<= 2'd0;
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
                else if(left_down_cnt>sec_v)
                    sec<= 2'd2;
            end
            3'd2: begin
                if(right_down_cnt>max_v)
                    sec<= max;
                else if(right_down_cnt>sec_v)
                    sec<= 2'd3;
        end
        endcase
    end
	else if(state_cs == OUTPUT)
		sec<= 2'd1;
end


always @(posedge CLK or posedge RST) begin
    if(RST)
        max_v<= 6'd0;
    else if(state_cs == COMP)begin
        case (cnt_7)
            3'd0: begin
                if (right_up_cnt>left_up_cnt) 
                    max_v<= right_up_cnt;
                else
                     max_v<= left_up_cnt;
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
	else if(state_cs == OUTPUT)
		max_v<= 6'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        sec_v<= 6'd0;
    else if(state_cs == COMP)begin
        case (cnt_7)
            3'd0: begin
                if (right_up_cnt<left_up_cnt) 
                    sec_v<= right_up_cnt;
                else
                    sec_v<= left_up_cnt;
            end
            3'd1: begin
                if(left_down_cnt>max_v)
                    sec_v<= max_v;
                else if(left_down_cnt>sec_v)
                    sec_v<=left_down_cnt;
            end
            3'd2: begin
                if(right_down_cnt>max_v)
                    sec_v<= max_v;
                else if(right_down_cnt>sec_v)  
                    sec_v<= right_down_cnt;
            end
        endcase
    end
	else if(state_cs == OUTPUT)
		sec_v<= 6'd0;
end

always @(posedge CLK or posedge RST) begin
    if(RST)
        DONE <= 1'd1;
    else if(state_cs == OUTPUT)
        DONE <= 1'd1;
    else 
        DONE <= 1'd0;
end

reg [4:0] in_cnt1_r [0:19];
reg [39:0] in_C1_r [0:19];
wire [4:0] max_value;

assign max_value = in_cnt1_r[cnt_64] + in_cnt2;

//max_circle1_x
integer j;
always @(posedge CLK) begin
    if(RST)begin
		for(j=0;j<20;j=j+1)begin
			max_circle1_x[j] <= 0;
			max_circle1_y[j] <= 0;
			in_cnt1_r[j] <= 0;
			in_C1_r[j] <= 0;
		end
		cnt_max <= 0;
	end
	else if(state_cs == CNT1)begin
		if(cnt_64 == 7'd63 && cnt_40 ==6'd39)begin
			cnt_max <= 0;
		end
		else if(in_cnt1 >= 5'd11 && cnt_40 == 6'd39 && cnt_max < 20)begin
			max_circle1_x[cnt_max] <= circle_x;
			max_circle1_y[cnt_max] <= circle_y;
			cnt_max <= cnt_max + 1;
			in_cnt1_r[cnt_max] <= in_cnt1;
			in_C1_r[cnt_max] <= in_C1;
		end
	end
	else if(state_cs == OUTPUT)begin
		for(j=0;j<20;j=j+1)begin
			max_circle1_x[j] <= 0;
			max_circle1_y[j] <= 0;
			in_cnt1_r[j] <= 0;
			in_C1_r[j] <= 0;
		end
		cnt_max <= 0;
	end
 end

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
	else if(state_cs == OUTPUT)begin
		in_C1_max<=40'd0;
        in_cnt1_max<=5'd0;
    end
end

//in_C2_max
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        in_C2_max<=40'd0;
        in_cnt2_max<=5'd0;
    end
    else if(state_cs == CNT2 && cnt_40==6'd39 && in_cnt2_max<max_value)begin
        in_C2_max<=in_C2;
        in_cnt2_max<=max_value;
    end
	else if(state_cs == OUTPUT)begin
		in_C2_max<=40'd0;
        in_cnt2_max<=5'd0;
    end
end

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        C1X <= 4'd0;
        C1Y <= 4'd0;
        C2X <= 4'd0;
        C2Y <= 4'd0;
    end
	else if(state_cs == CNT1 || state_cs == CNT2)begin
		if(cnt_40==6'd39 && in_cnt1_max<in_cnt1)begin
            C1X <= circle_x;
            C1Y <= circle_y;
        end
		else if(cnt_40==6'd39 && in_cnt2_max<max_value)begin
            C1X <= max_circle1_x[cnt_64];
			C1Y <= max_circle1_y[cnt_64];
			C2X <= circle_x;
            C2Y <= circle_y;
        end
	end
end

parameter x_small = 4,
	      x_large = 7,
		  y_small = 2,
		  y_large = 7;

reg [4:0] cnt2_x, cnt2_y;


always @(posedge CLK or posedge RST)begin
	if(RST)
		cnt_24<= 0;
	else if(state_cs == CNT2 && cnt_40 == 39)
		if(cnt_24 == 23)
			cnt_24 <= 0;
		else 
			cnt_24<= cnt_24 + 1;
end

always @(posedge CLK or posedge RST)begin
	if(RST)begin
		cnt2_x <= 5'd4;
		cnt2_y <= 5'd2;
	end
	else if(state_cs == CNT2 && cnt_24 == 23)begin
		cnt2_x <= 5'd4;
		cnt2_y <= 5'd2;
	end
	else if(state_cs == CNT2 && cnt_40 == 39)
		if(cnt2_y != 7)
			cnt2_y <= cnt2_y + 1;
		else if(cnt2_y == 7 && cnt2_x != 7)begin
			cnt2_x <= cnt2_x + 1;
			cnt2_y <= 5'd2;
		end
		else begin
			cnt2_x <= 5'd4;
			cnt2_y <= 5'd2;
		end
end

wire [3:0] xxxx,yyyy;

assign xxxx = max_circle1_x[cnt_64];
assign yyyy = max_circle1_y[cnt_64];

//circle_x circle_y
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        circle_x <= 4'd0;
        circle_y <= 4'd0;
    end
    else if(state_cs == CNT1) begin
        if(cnt_64==7'd0 && cnt_40==6'd0)   // start point
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
		if(cnt_40 == 0 && cnt_64 == 0)begin
			if(max_circle1_x[cnt_64] == 2 && max_circle1_y[cnt_64] == 10)begin
				circle_x <= max_circle1_x[cnt_64] + cnt2_x;
				circle_y <= max_circle1_y[cnt_64] + cnt2_y;
			end
			else if(max_circle1_x[cnt_64] > 7)begin
				if(max_circle1_y[cnt_64] > 7)begin
					circle_x <= max_circle1_x[cnt_64] - cnt2_x;
					circle_y <= max_circle1_y[cnt_64] - cnt2_y;
				end
				else begin
					circle_x <= max_circle1_x[cnt_64] - cnt2_x;
					circle_y <= max_circle1_y[cnt_64] + cnt2_y;
				end
			end
			else begin
				if(max_circle1_y[cnt_64] > 7)begin
					circle_x <= max_circle1_x[cnt_64] + cnt2_x;
					circle_y <= max_circle1_y[cnt_64] - cnt2_y;
				end
				else begin
					circle_x <= max_circle1_x[cnt_64] + cnt2_x;
					circle_y <= max_circle1_y[cnt_64] + cnt2_y;
				end
			end
		end
		else if(cnt_40 == 39)begin
			if(max_circle1_x[cnt_64] == 2 && max_circle1_y[cnt_64] == 10)begin
				circle_x <= max_circle1_x[cnt_64] + cnt2_x;
				circle_y <= max_circle1_y[cnt_64] + cnt2_y;
			end
			else if(max_circle1_x[cnt_64] > 7)begin
				if(max_circle1_y[cnt_64] > 7)begin
					circle_x <= max_circle1_x[cnt_64] - cnt2_x;
					circle_y <= max_circle1_y[cnt_64] - cnt2_y;
				end
				else begin
					circle_x <= max_circle1_x[cnt_64] - cnt2_x;
					circle_y <= max_circle1_y[cnt_64] + cnt2_y;
				end
			end
			else begin
				if(max_circle1_y[cnt_64] > 7)begin
					circle_x <= max_circle1_x[cnt_64] + cnt2_x;
					circle_y <= max_circle1_y[cnt_64] - cnt2_y;
				end
				else begin
					circle_x <= max_circle1_x[cnt_64] + cnt2_x;
					circle_y <= max_circle1_y[cnt_64] + cnt2_y;
				end
			end
		end
    end
end

wire [3:0] sel_Xin,sel_Yin;

assign sel_Xin = (state_cs == CNT1) ? X_in[cnt_40] : X_in[cnt_40];
assign sel_Yin = (state_cs == CNT1) ? Y_in[cnt_40] : Y_in[cnt_40];

assign x_mis=(circle_x > sel_Xin)? circle_x - sel_Xin: sel_Xin-circle_x;
assign y_mis=(circle_y > sel_Yin)? circle_y - sel_Yin: sel_Yin-circle_y;
assign mis_b=(x_mis>y_mis)?x_mis:y_mis;
assign mis_s=(x_mis>y_mis)?y_mis:x_mis;

//determine dot in the circle
always @(posedge CLK or posedge RST) begin
    if(RST)begin
        in_cnt1 <= 5'd0;
        in_C1<=40'd0;
    end
    else if(state_cs == CNT1)begin
        if(cnt_40==6'd39)begin
			in_cnt1 <= 5'd0;
			in_C1<=40'd0;
        end
        else if(mis_b==4 && mis_s==0)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
        else if(mis_b==3 && mis_s<3)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
        else if(mis_b<3)begin
            in_C1[cnt_40]<=1;
            in_cnt1<=in_cnt1+1;
        end
    end
end

wire [3:0] X_in40,Y_in40;
wire iv_C1_max;
assign iv_C1_max = ~in_C1_max[cnt_40];
assign X_in40 = X_in[cnt_40];
assign Y_in40 = Y_in[cnt_40];

always @(posedge CLK or posedge RST) begin
    if(RST)begin
        in_cnt2 <= 5'd0;
        in_C2<=40'd0;
    end
    else if(state_cs == CNT2 && ~in_C1_r[cnt_64][cnt_40])begin
        if(cnt_40==6'd39)begin
			in_cnt2 <= 5'd0;
			in_C2<=40'd0;
        end
		else if(circle_x == 8 && circle_y == 12 && max_circle1_x[cnt_64] == 2 && max_circle1_y[cnt_64] == 10)begin
			in_cnt2 <= 5'd12;
			in_C2<=40'd0;
		end
        else if(mis_b==4 && mis_s==0)begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
        else if(mis_b==3 && mis_s<3)begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
        else if(mis_b<3 )begin
            in_C2[cnt_40]<=1;
            in_cnt2<=in_cnt2+1;
        end
    end
end

endmodule
