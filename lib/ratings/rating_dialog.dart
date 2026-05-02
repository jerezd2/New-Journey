import 'package:flutter/material.dart';

Future<double?> showRatingDialog(BuildContext context) async {
  double selectedRating = 0;

  return showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Rate this place'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;

                return IconButton(
                  icon: Icon(
                    selectedRating >= starIndex
                        ? Icons.star
                        : Icons.star_border,
                        color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedRating = starIndex.toDouble();
                    });
                  },
                );
              }),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, selectedRating),
            child: const Text('Submit'),
          ),
        ],
      );
    },
  );
}