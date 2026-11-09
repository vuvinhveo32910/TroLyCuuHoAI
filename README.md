# WebVinhNam — Gemini và MedGemma trên server nội bộ

Giữ nguyên giao diện và API Gemini của nhóm. Trong ChatBox, nút chọn model có hai nhánh độc lập: **Gemini** gọi `GeminiService` hiện có; **MedGemma** gọi API Python chạy model thật trên máy chủ. Nhánh MedGemma không chuyển sang Gemini khi lỗi.

## Chạy trên máy hiện tại

Mở PowerShell tại `D:\DATA\.CODEX\DoAnVinhPhatNam\WebVinhNam_Server`:

```powershell
.\Build-Web.ps1
.\Run-Server.ps1 -Lan
```

Chỉ build lại sau khi đổi mã Flutter. Giữ terminal chạy; Ctrl+C dừng cả web và API. Mở `http://127.0.0.1:8080`, vào **ChatBox AI**, bấm nút chọn model rồi chọn **MedGemma 1.5 4B**. Gemini vẫn giữ lựa chọn mặc định của bản nhóm.

`Run-Server.ps1` dùng Python `D:\Models\medgemma-env\Scripts\python.exe`; đổi bằng `-Python` nếu cần. `Build-Web.ps1` dùng Flutter `D:\flutter\bin\flutter.bat`; đổi bằng `-Flutter` nếu cần.

## Máy khác hoặc điện thoại trong cùng mạng

Máy chủ chạy `Run-Server.ps1 -Lan`; terminal in các địa chỉ dạng `http://192.168.x.x:8080/`. Thiết bị còn lại mở địa chỉ IPv4 của Wi-Fi/LAN máy chủ bằng trình duyệt. Không dùng `127.0.0.1` trên thiết bị còn lại. Máy chỉ mở web không cần tải model hay cài Flutter.

Nếu Windows chặn kết nối, dùng PowerShell **Run as administrator** chạy một lần:

```powershell
& "D:\DATA\.CODEX\DoAnVinhPhatNam\WebVinhNam_Server\Enable-Lan.ps1"
```

Chạy lệnh khi server đang hoạt động. Script xác minh đúng tiến trình dự án rồi cho Python đó nhận TCP 8080 từ `LocalSubnet`, chỉ trên card mạng đang dùng và profile hiện tại (Private hoặc Public). Có thể chọn card bằng `-InterfaceAlias "Wi-Fi"`. Dùng mạng tin cậy/hotspot của nhóm; Wi-Fi khách hoặc mạng trường có thể chặn thiết bị trao đổi với nhau. Script không đổi loại mạng hay mở cổng router Internet. Windows yêu cầu quyền quản trị để thêm quy tắc này.

Web và API cùng địa chỉ nên không phải sửa IP trong Flutter khi chuyển mạng. Nếu máy có nhiều card mạng/VPN, chọn địa chỉ của card kết nối với thiết bị còn lại; dùng `ipconfig` để đối chiếu.

Nếu điện thoại timeout sau khi script báo `Allowed LocalSubnet`, kiểm tra các quy tắc **Block** trong **Inbound Rules** của Windows Firewall cho `python.exe` và cổng TCP 8080. Quy tắc Block có ưu tiên cao hơn Allow khi cùng khớp một kết nối. [Quy tắc ưu tiên của Windows Firewall](https://learn.microsoft.com/en-za/windows/security/operating-system-security/network-security/windows-firewall/rules)

Chat và tải ảnh từ tệp dùng được qua HTTP LAN. Camera/clipboard có thể yêu cầu HTTPS được thiết bị tin cậy; xem [giới hạn secure context của trình duyệt](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia). Với demo HTTP, dùng **Chọn ảnh từ máy**.

## Model và dữ liệu

- Máy hiện tại đặt MedGemma ở `D:\DATA\.CODEX\DoAnVinhPhatNam\medgemma-1.5-4b-it` và trỏ `MEDGEMMA_MODEL_PATH` đến đó trong `backend/.env.local`. Thành viên dùng máy khác tự tải model bằng tài khoản Hugging Face của mình và đặt đường dẫn theo [hướng dẫn backend](backend/README.md).
- YOLO: `lib/AI_Model/best.pt`, chạy CPU trong cùng tiến trình API. Không mở thêm server YOLO cổng 8000 cho luồng mới.
- SQLite: `backend/runtime/knowledge_base/so_cuu.sqlite3`; báo cáo/manifest đi cùng. PDF ở `backend/runtime/TaiLieuNguon`. Runtime được cung cấp riêng, không đi theo Git.
- Gemini: các tệp `lib/core/gemini/` và cách cấu hình API hiện có của nhóm được giữ nguyên.

MedGemma là bản 1.5 4B, trọng số trên đĩa BF16; lúc nạp dùng NF4 4-bit, double quantization và SDPA. Nạp một lần và giữ trong bộ nhớ cho các thiết bị dùng chung. Có nguồn phù hợp thì trả SQLite và trang PDF ngay; thiếu nguồn mới gọi model. Phản hồi ghi rõ nguồn và trạng thái duyệt. Bộ hiện có 21 mục tham khảo demo, chưa có mục được duyệt chuyên môn.

Nhiều thiết bị dùng chung GPU; yêu cầu sinh đồng thời có thể nhận thông báo bận và cần gửi lại. Chia máy chủ/máy khách không tự làm GPU chạy nhanh hơn. Máy chủ cần đủ RAM/bộ nhớ ảo và chỉ chạy một bản MedGemma.

## Cấu trúc server

`backend/run_local_server.py` chạy một tiến trình gồm API riêng trên `127.0.0.1:8765` và web/gateway cổng 8080. Gateway chỉ chuyển các API chat, trạng thái, ảnh, tra nguồn và PDF. API quản trị nguồn dùng trực tiếp trên máy chủ: `http://127.0.0.1:8765/admin`.

Chạy `Run-Server.ps1` không có `-Lan` để chỉ nghe localhost. Dùng `-NoPreload` nếu chỉ thử kho/YOLO. Đây là cấu hình demo nội bộ; triển khai Internet cần máy chủ HTTPS và xác thực phù hợp.

Khi sửa Flutter, `Run-Web.ps1` mở bản phát triển tại `http://127.0.0.1:8081`, gọi API cổng 8765. Nếu `Run-Server.ps1 -Lan` đang chạy thì dùng luôn API đó, không mở thêm `Run-Chat.ps1`. Nếu chưa có API, mở `Run-Chat.ps1` trong terminal riêng. Có thể đổi cổng phát triển bằng `Run-Web.ps1 -Port 8082`. Bản demo cho thiết bị cùng mạng vẫn dùng cổng 8080. Máy ít RAM nên dùng bản demo đã build để giảm lượng bộ nhớ cần cho trình biên dịch Flutter.

## Kiểm tra

```powershell
& "D:\Models\medgemma-env\Scripts\python.exe" -X utf8 -B -m unittest discover -s backend -p "test_*.py"
& "D:\flutter\bin\flutter.bat" analyze
& "D:\flutter\bin\flutter.bat" test
```
