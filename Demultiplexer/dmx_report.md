Test đơn ( Chỉ test 1 trường hợp 1 lần, không dùng reset )
1) random dir -- 6 packet ( 88 byte/packet) -- random ready
- Xuất hiện glitch và sau đó data bị nhảy sang 1 kênh (dir_i) khác)
- Test data_o:
- Test empty_o:
- Test channel_o: 

2) dir_i = 3 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

3) dir_i = 2 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

4) dir_i = 1 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

5) dir_i = 0 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

6) random dir -- 6 packet ( 88 byte/packet) -- ready = 1 (Cố định ready, kt xem có bị lỗi chuyển kênh hay không) // assert_ready(100,100,0,0);
- Không có glitch 
- Không bị lỗi chuyển kênh nhưng có 1 kênh bị truyền dư dữ liệu ( 75 ps )
- Test data_o:
- Test empty_o:
- Test channel_o:

7) random dir -- 6 packet ( 88 byte/packet) -- ready = 0 (Cố định ready, kt xem có bị lỗi chuyển kênh hay không) // assert_ready(0,0,150,150);
- Không có glitch 
- Không bị lỗi chuyển kênh nhưng có 1 kênh bị truyền dư dữ liệu ( 75 ps )
- Test data_o: Không có data
- Test empty_o: Không có empty
- Test channel_o: Không có channel

//Test data
8) data < WORD_IN ( Số lượng byte trong 1 packet < 8 ) -- ready = 1 assert_ready(150,150,0,0);
- Không có lỗi về data









 