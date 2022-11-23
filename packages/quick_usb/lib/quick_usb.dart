import 'dart:typed_data';

import 'src/common.dart';
import 'src/quick_usb_platform_interface.dart';

export 'src/common.dart';
export 'src/quick_usb_android.dart';
export 'src/quick_usb_desktop.dart';

QuickUsbPlatform get _platform => QuickUsbPlatform.instance;

class QuickUsb {
  static Future<bool> init() => _platform.init();

  static Future<void> exit() => _platform.exit();

  static Future<List<UsbDevice>> getDeviceList() => _platform.getDeviceList();

  /// [requestPermission] If true, Android will ask permission for each USB
  /// device if required. Only required to retrieve the serial number.
  static Future<List<UsbDeviceDescription>> getDevicesWithDescription({
    bool requestPermission = true,
  }) =>
      _platform.getDevicesWithDescription(requestPermission: requestPermission);

  /// [requestPermission] If true, Android will ask permission for the USB device
  /// if required. Only required to retrieve the serial number.
  static Future<UsbDeviceDescription> getDeviceDescription(
    UsbDevice usbDevice, {
    bool requestPermission = true,
  }) =>
      _platform.getDeviceDescription(
        usbDevice,
        requestPermission: requestPermission,
      );

  static Future<bool> hasPermission(UsbDevice usbDevice) =>
      _platform.hasPermission(usbDevice);

  static Future<bool> requestPermission(UsbDevice usbDevice) =>
      _platform.requestPermission(usbDevice);

  static Future<bool> openDevice(UsbDevice usbDevice) =>
      _platform.openDevice(usbDevice);

  static Future<void> closeDevice() => _platform.closeDevice();

  static Future<UsbConfiguration> getConfiguration(int index) =>
      _platform.getConfiguration(index);

  static Future<bool> setConfiguration(UsbConfiguration config) =>
      _platform.setConfiguration(config);

  static Future<bool> detachKernelDriver(UsbInterface intf) =>
      _platform.detachKernelDriver(intf);

  static Future<bool> claimInterface(UsbInterface intf) =>
      _platform.claimInterface(intf);

  static Future<bool> releaseInterface(UsbInterface intf) =>
      _platform.releaseInterface(intf);

  static Future<Uint8List> bulkTransferIn(UsbEndpoint endpoint, int maxLength,
          {int timeout = 1000}) =>
      _platform.bulkTransferIn(endpoint, maxLength, timeout);

  static Future<int> bulkTransferOut(UsbEndpoint endpoint, Uint8List data,
          {int timeout = 1000}) =>
      _platform.bulkTransferOut(endpoint, data, timeout);

  static Future<void> setAutoDetachKernelDriver(bool enable) =>
      _platform.setAutoDetachKernelDriver(enable);

  static Future<int> sendControlMessage(
    UsbInterface interface, {
    required int requestType,
    required int request,
    required int value,
    List<int>? data,
  }) =>
      _platform.sendControlMessage(
        interface,
        requestType: requestType,
        request: request,
        value: value,
        data: data,
      );
}

class CP210 {
  static final CP210x_SET_BAUDRATE = 0x1E;
  static final CP210x_IFC_ENABLE = 0x00;
  static final CP210x_SET_LINE_CTL = 0x03;
  static final CP210x_SET_MHS = 0x07;

  List<int> baudRateData(int baudRate) {
    return List.of([
      baudRate & 0xff,
      (baudRate >> 8) & 0xff,
      (baudRate >> 16) & 0xff,
      (baudRate >> 24) & 0xff,
    ]);
  }

  static const cp210xLineCtlDefault = 0x0800;
  static const cp210xMHSDefault = 0x0000;

  static const cp210xRequestType_Host2Device = 0x41;

  Future<bool> initialiseUart(int baudRate, UsbInterface interface) async {
    await QuickUsb.sendControlMessage(
      interface,
      requestType: cp210xRequestType_Host2Device,
      request: CP210x_IFC_ENABLE,
      value: cp210xLineCtlDefault,
      data: null,
    );

    await QuickUsb.sendControlMessage(
      interface,
      requestType: cp210xRequestType_Host2Device,
      request: CP210x_IFC_ENABLE,
      value: cp210xLineCtlDefault,
    );

    await QuickUsb.sendControlMessage(
      interface,
      requestType: cp210xRequestType_Host2Device,
      request: CP210x_SET_LINE_CTL,
      value: 0,
    );

    final List<int> flowControl = List.of([1, 0, 0, 0, 64, 0, 0, 0, 0, -128, 0, 0, 0, 32, 0, 0]);

    await QuickUsb.sendControlMessage(
      interface,
      requestType: cp210xRequestType_Host2Device,
      request: CP210x_SET_LINE_CTL,
      value: 0,
      data: flowControl,
    );

    await QuickUsb.sendControlMessage(
      interface,
      requestType: cp210xRequestType_Host2Device,
      request: CP210x_SET_MHS,
      value: cp210xMHSDefault,
    );

    await QuickUsb.sendControlMessage(
      interface,
      requestType: cp210xRequestType_Host2Device,
      request: CP210x_SET_BAUDRATE,
      value: 0,
      data: baudRateData(baudRate),
    );

    return true;
  }
}
