import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  debugRepaintRainbowEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RepaintBoundary Sample App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RepaintBoundarySample(),
    );
  }
}

class RepaintBoundarySample extends StatefulWidget {
  const RepaintBoundarySample({super.key});

  @override
  State<RepaintBoundarySample> createState() => _RepaintBoundarySampleState();
}

class _RepaintBoundarySampleState extends State<RepaintBoundarySample> {
  GlobalKey<State<StatefulWidget>> widget1RenderKey =
      GlobalKey<State<StatefulWidget>>();

  /*
      * Get the view context from the key
      * Converts view to png 
      * Extract the UI8List 
      * Convert the png to a pdf
      * Download to Storage
      */

//Download Recipt Function
  void downloadTransactionReceipt() async {
    // Get the view context from the key
    final RenderRepaintBoundary boundary = widget1RenderKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage(pixelRatio: 1.5);

// Converts view to png
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

// Extract the UI8List
    final Uint8List uint8List = byteData!.buffer.asUint8List();

// Convert the png to a pdf
    final Uint8List pdfData = await convertPngUint8ListToPdf(uint8List);

// Download to Storage
    await downloadToStorageFunction(pdfData, "Transaction Receipt");
  }

  //Function to covert our png Uint8List
  Future<Uint8List> convertPngUint8ListToPdf(Uint8List imageBytes) {
    final pdf = pw.Document();

    // Create an image widget from the image bytes
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          // Calculate the width and height of the A4 page
          final double a4PageWidth = PdfPageFormat.a4.width;
          final double a4PageHeight = PdfPageFormat.a4.height;

          // Calculate the image width and height to fit the A4 page
          double imageWidth = a4PageWidth;
          double imageHeight = a4PageHeight;

          // Calculate the aspect ratio of the image
          final double imageAspectRatio =
              image.width!.toDouble() / image.height!.toDouble();

          if (imageAspectRatio < 1.0) {
            // Image is taller than wide
            imageWidth = imageHeight * imageAspectRatio;
          } else {
            // Image is wider than tall
            imageHeight = imageWidth / imageAspectRatio;
          }

          return pw.Center(
            child: pw.Image(
              image,
              width: imageWidth,
              height: imageHeight,
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  //  Download to Storage

  Future<void> downloadToStorageFunction(
      Uint8List pdfData, String documentName) async {
    final tempDir = await getTemporaryDirectory();

    final pdfFile = File('${tempDir.path}/$documentName.pdf');
    await pdfFile.writeAsBytes(pdfData);

    // Perform the selected action

    var path = "";
    // Optionally, you can use a file picker package to let the user choose a download location
    // For simplicity, we'll save the file to the app's documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    final downloadFile = File('${appDocDir.path}/$documentName.pdf');
    await pdfFile.copy(downloadFile.path);
    if (Platform.isAndroid == true) {
      var output = await getExternalStorageDirectory();
      path = output!.absolute.path;
    } else {
      var output = await getApplicationDocumentsDirectory();
      path = output.path;
    }

    final file = File('$path/$documentName.pdf');

    await file.writeAsBytes(pdfData);

    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("RepaintBoundary Sample App"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RepaintBoundary(
            key: widget1RenderKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Transaction Receipt',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      for (final receiptItem in ReceiptBank.receiptData)
                        Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  receiptItem.title,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        receiptItem.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            )
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
              onPressed: () {
                downloadTransactionReceipt();
              },
              child: const Text("Download"))
        ],
      ),
    );
  }
}

class ReceiptBank {
  final String title;
  final String value;
  ReceiptBank({required this.title, required this.value});

  static final receiptData = [
    ReceiptBank(title: "Transction Amount", value: "\$3000"),
    ReceiptBank(title: "Transaction Type", value: "Investment"),
    ReceiptBank(title: "Narration", value: "This is the transaction narration"),
  ];
}
