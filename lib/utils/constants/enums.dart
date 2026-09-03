/* --
      LIST OF Enums
      They cannot be created inside a class.
-- */

enum AppRole { admin, user }

enum Role { admin, manager, operator, fleetOwner, fleetManager, fleetOperator, driver, user, unknown }

enum ChatType { support }

enum ChatMessageStatus { sending, sent, delivered, read, failed }

enum TransactionType { buy, sell }

enum DiscountType { percentage, flat }

enum TextSizes { small, medium, large }

enum ProductVisibility { published, hidden }

enum ImageType { asset, network, memory, file }

enum ProductType { simple, digital, variable }

enum ShippingMethod { standard, express, overnight }

enum ShippingStatus { pending, inTransit, delivered, canceled }

enum MediaCategory { none, banners, brands, categories, products, personalized }

enum PaymentMethods { cash, card, paypal }

enum BannerTargetType {
  none,
  productScreen,
  categoryScreen,
  brandScreen,
  customUrl,
  homeScreen,
  shopScreen,
  favouriteScreen,
  settingScreen,
  cart,
  orders,
  profile
}

enum UnitType {
  unitLess,
  length, // e.g., meters, kilometers, miles
  weight, // e.g., grams, kilograms, pounds
  volume, // e.g., liters, milliliters, cubic meters
  temperature, // e.g., Celsius, Fahrenheit, Kelvin
  time, // e.g., seconds, minutes, hours
  area, // e.g., square meters, acres, hectares
  speed, // e.g., meters per second, kilometers per hour, miles per hour
  pressure, // e.g., pascal, bar, psi
  energy, // e.g., joules, kilojoules, calories, kilocalories
  power, // e.g., watts, kilowatts, horsepower
  frequency, // e.g., hertz, kilohertz, gigahertz
  fuelEfficiency, // e.g., liters per 100 kilometers, miles per gallon
  angle, // e.g., degrees, radians, gradians
  currency, // e.g., USD, EUR, GBP
  density, // e.g., kilograms per cubic meter, grams per cubic centimeter
  force, // e.g., newtons, pounds-force
  luminosity, // e.g., lumens, candelas
  dataStorage, // e.g., bytes, kilobytes, megabytes, gigabytes
  electricCurrent, // e.g., amperes, milliamperes
  voltage, // e.g., volts, millivolts
  capacitance, // e.g., farads, microfarads
  resistance, // e.g., ohms, milliohms
  inductance, // e.g., henries, millihenries
  magneticField, // e.g., teslas, gauss
  radioactivity, // e.g., becquerels, curies
  concentration, // e.g., moles per liter, parts per million (ppm)
  acidity, // pH level
  illumination, // e.g., lux, foot-candles
  torque, // e.g., newton-meters, pound-feet
}

enum ReturnStatus {
  requested,
  underReview,
  approved,
  rejected,
  refundProcessed,
  exchangeProcessed,
  completed,
  canceled,
}

enum ReturnType {
  returnForRefund,
  exchange,
  returnAndExchange
}

enum ReturnReason {
  damagedProduct,
  wrongItem,
  sizeIssue,
  qualityIssue,
  notAsDescribed,
  changedMind,
  other
}

