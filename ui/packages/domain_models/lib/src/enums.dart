enum OrderStatus {
  pending,
  confirmed,
  assigned,
  pickedUp,
  onTheWay,
  delivered,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.assigned:
        return 'Rider Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'assigned':
        return OrderStatus.assigned;
      case 'picked_up':
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'on_the_way':
      case 'ontheway':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.assigned:
        return 'assigned';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

enum PaymentStatus {
  unpaid,
  paid;

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid (COD)';
      case PaymentStatus.paid:
        return 'Paid (COD)';
    }
  }

  static PaymentStatus fromString(String value) {
    return value.toLowerCase() == 'paid' ? PaymentStatus.paid : PaymentStatus.unpaid;
  }

  String toJson() => name;
}

enum RiderStatus {
  available,
  busy,
  offline;

  String get label {
    switch (this) {
      case RiderStatus.available:
        return 'Available';
      case RiderStatus.busy:
        return 'Busy';
      case RiderStatus.offline:
        return 'Offline';
    }
  }

  static RiderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return RiderStatus.available;
      case 'busy':
        return RiderStatus.busy;
      case 'offline':
      default:
        return RiderStatus.offline;
    }
  }

  String toJson() => name;
}

enum UserRole {
  customer,
  rider,
  admin;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'rider':
        return UserRole.rider;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String toJson() => name;
}
