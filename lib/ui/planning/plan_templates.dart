import 'package:flutter/material.dart';
import '../../models.dart';

class PlanTemplate {
  final String id;
  final String name;
  final PlanType type;
  final IconData icon;
  final double budget;
  final List<PlanItineraryItem> itinerary;
  final List<PlanTask> checklist;

  PlanTemplate({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.budget,
    required this.itinerary,
    required this.checklist,
  });

  static List<PlanTemplate> get all => [
    PlanTemplate(
      id: 'sea_trip',
      name: 'Du lịch biển',
      type: PlanType.trip,
      icon: Icons.beach_access_rounded,
      budget: 8000000,
      itinerary: [
        PlanItineraryItem(day: 1, time: "09:00", activity: "Check-in & Ăn trưa", location: "Resort Hải Dương", estimatedCost: 500000),
        PlanItineraryItem(day: 1, time: "16:00", activity: "Tắm biển & Team Building", location: "Bãi biển chính", estimatedCost: 0),
        PlanItineraryItem(day: 2, time: "08:00", activity: "Tour 4 Đảo & Lặn ngắm san hô", location: "Bến cảng", estimatedCost: 1200000),
        PlanItineraryItem(day: 2, time: "19:00", activity: "Gala Dinner ngoài trời", location: "Resort", estimatedCost: 800000),
        PlanItineraryItem(day: 3, time: "09:00", activity: "Mua sắm đặc sản", location: "Chợ địa phương", estimatedCost: 1000000),
      ],
      checklist: [
        PlanTask(title: "Kem chống nắng (SPF 50+)", category: Category.health, priority: PlanPriority.high),
        PlanTask(title: "Đặt vé máy bay (2 chiều)", category: Category.transport, estimatedCost: 2500000, priority: PlanPriority.high),
        PlanTask(title: "Booking Resort / Khách sạn", category: Category.home, estimatedCost: 4000000, priority: PlanPriority.high),
        PlanTask(title: "Chuẩn bị Đồ bơi, Kính mát, Mũ rộng vành", category: Category.shopping),
        PlanTask(title: "Túi chống nước cho điện thoại", category: Category.other),
      ],
    ),
    PlanTemplate(
      id: 'city_break',
      name: 'City Break',
      type: PlanType.trip,
      icon: Icons.location_city_rounded,
      budget: 4000000,
      itinerary: [
        PlanItineraryItem(day: 1, time: "10:00", activity: "Dạo quanh phố cổ & Cafe", location: "Khu trung tâm", estimatedCost: 100000),
        PlanItineraryItem(day: 1, time: "15:00", activity: "Tham quan di tích lịch sử", location: "Bảo tàng", estimatedCost: 80000),
        PlanItineraryItem(day: 2, time: "09:00", activity: "Shopping tại trung tâm thương mại", location: "Grand Mall", estimatedCost: 0),
        PlanItineraryItem(day: 2, time: "20:00", activity: "Xem show nghệ thuật", location: "Rạp hát", estimatedCost: 500000),
      ],
      checklist: [
        PlanTask(title: "Giày đi bộ êm chân", category: Category.shopping),
        PlanTask(title: "Cài đặt các ứng dụng gọi xe / bản đồ", category: Category.other, priority: PlanPriority.high),
        PlanTask(title: "Sạc dự phòng", category: Category.other, priority: PlanPriority.high),
      ],
    ),
    PlanTemplate(
      id: 'hiking',
      name: 'Leo núi/Camping',
      type: PlanType.trip,
      icon: Icons.terrain_rounded,
      budget: 3500000,
      itinerary: [
        PlanItineraryItem(day: 1, time: "05:00", activity: "Tập trung & Di chuyển tới chân núi", location: "Điểm hẹn", estimatedCost: 200000),
        PlanItineraryItem(day: 1, time: "10:00", activity: "Bắt đầu Trekking chặng 1", location: "Rừng quốc gia", estimatedCost: 0),
        PlanItineraryItem(day: 1, time: "16:00", activity: "Dựng lều & Nấu ăn tối", location: "Trạm dừng chân 1", estimatedCost: 100000),
        PlanItineraryItem(day: 2, time: "04:30", activity: "Leo đỉnh ngắm bình minh", location: "Đỉnh núi", estimatedCost: 0),
        PlanItineraryItem(day: 2, time: "13:00", activity: "Hạ sơn & Ăn mừng", location: "Chân núi", estimatedCost: 300000),
      ],
      checklist: [
        PlanTask(title: "Giày leo núi có độ bám tốt", category: Category.shopping, priority: PlanPriority.high),
        PlanTask(title: "Balo trợ lực (30L-45L)", category: Category.shopping),
        PlanTask(title: "Đồ sơ cứu y tế (Băng cá nhân, thuốc tiêu hóa)", category: Category.health, priority: PlanPriority.high),
        PlanTask(title: "Đèn pin đội đầu & Pin dự phòng", category: Category.other, priority: PlanPriority.high),
        PlanTask(title: "Lương khô, Chocolate, Nước uống (3 lít)", category: Category.food, priority: PlanPriority.high),
      ],
    ),
    PlanTemplate(
      id: 'food_tour',
      name: 'Food Tour',
      type: PlanType.trip,
      icon: Icons.ramen_dining_rounded,
      budget: 2000000,
      itinerary: [
        PlanItineraryItem(day: 1, time: "07:30", activity: "Phở sáng truyền thống", location: "Quán Phở cổ", estimatedCost: 60000),
        PlanItineraryItem(day: 1, time: "10:00", activity: "Cà phê trứng", location: "Quán cũ", estimatedCost: 45000),
        PlanItineraryItem(day: 1, time: "12:30", activity: "Bún chả / Bánh xèo", location: "Quán địa phương", estimatedCost: 80000),
        PlanItineraryItem(day: 1, time: "18:00", activity: "Ốc & Ăn vặt tối", location: "Khu ăn vặt", estimatedCost: 150000),
      ],
      checklist: [
        PlanTask(title: "Lên danh sách 10 quán phải thử", category: Category.education),
        PlanTask(title: "Thuốc hỗ trợ tiêu hóa", category: Category.health, priority: PlanPriority.high),
        PlanTask(title: "Sạc dự phòng đầy pin (Để quay phim/chụp ảnh)", category: Category.other),
      ],
    ),
    PlanTemplate(
      id: 'monthly',
      name: 'Chi tiêu tháng',
      type: PlanType.living,
      icon: Icons.calendar_month_rounded,
      budget: 12000000,
      itinerary: [],
      checklist: [
        PlanTask(title: "Tiền thuê nhà / Phí quản lý", category: Category.home, estimatedCost: 6000000, priority: PlanPriority.high),
        PlanTask(title: "Tiền Điện, Nước, Rác", category: Category.bills, estimatedCost: 1200000),
        PlanTask(title: "Gói cước Internet & Di động", category: Category.bills, estimatedCost: 400000),
        PlanTask(title: "Ngân sách ăn uống (Chợ/Siêu thị)", category: Category.food, estimatedCost: 3500000, priority: PlanPriority.high),
        PlanTask(title: "Phí gửi xe", category: Category.transport, estimatedCost: 200000),
      ],
    ),
    PlanTemplate(
      id: 'moving',
      name: 'Chuyển nhà',
      type: PlanType.living,
      icon: Icons.local_shipping_rounded,
      budget: 5000000,
      itinerary: [],
      checklist: [
        PlanTask(title: "Mua Thùng Carton, Băng keo, Xốp nổ", category: Category.shopping, estimatedCost: 500000, priority: PlanPriority.high),
        PlanTask(title: "Liên hệ dịch vụ xe tải / Vận chuyển", category: Category.transport, estimatedCost: 2000000, priority: PlanPriority.high),
        PlanTask(title: "Phân loại đồ đạc & Thanh lý đồ cũ", category: Category.other),
        PlanTask(title: "Dọn dẹp & Vệ sinh nhà mới", category: Category.home, estimatedCost: 500000),
        PlanTask(title: "Cài đặt Internet, Điện lưới, Nước", category: Category.bills, priority: PlanPriority.high),
      ],
    ),
    PlanTemplate(
      id: 'wedding',
      name: 'Đám cưới',
      type: PlanType.event,
      icon: Icons.favorite_rounded,
      budget: 150000000,
      itinerary: [],
      checklist: [
        PlanTask(title: "Đặt cọc trung tâm tiệc cưới", category: Category.home, estimatedCost: 50000000, priority: PlanPriority.high),
        PlanTask(title: "Chọn mẫu & In thiệp mời (500 khách)", category: Category.shopping, estimatedCost: 5000000),
        PlanTask(title: "Thuê ekip Quay phim & Chụp ảnh", category: Category.other, estimatedCost: 15000000),
        PlanTask(title: "May/Thuê Váy cưới & Vest", category: Category.shopping, estimatedCost: 20000000, priority: PlanPriority.high),
        PlanTask(title: "Đặt nhẫn cưới", category: Category.shopping, estimatedCost: 15000000, priority: PlanPriority.high),
        PlanTask(title: "Hợp đồng Hoa tươi & Trang trí", category: Category.other, estimatedCost: 10000000),
        PlanTask(title: "Gửi thiệp mời (Trước 1 tháng)", category: Category.other, priority: PlanPriority.high),
      ],
    ),
    PlanTemplate(
      id: 'exam',
      name: 'Mùa thi cử',
      type: PlanType.event,
      icon: Icons.edit_document,
      budget: 3000000,
      itinerary: [],
      checklist: [
        PlanTask(title: "Đăng ký lệ phí thi chứng chỉ", category: Category.education, estimatedCost: 2500000, priority: PlanPriority.high),
        PlanTask(title: "Lên lịch ôn tập (12 tuần)", category: Category.education),
        PlanTask(title: "Mua tài liệu / Khóa học online", category: Category.education, estimatedCost: 500000),
        PlanTask(title: "Chuẩn bị Thẻ dự thi & Giấy tờ gốc", category: Category.other, priority: PlanPriority.high),
        PlanTask(title: "Bút chì, Tẩy, Máy tính bỏ túi", category: Category.shopping),
      ],
    ),
  ];
}
