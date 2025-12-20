import 'package:flutter/material.dart';

class RateCalculatorDialog extends StatefulWidget {
  final double? currentRate;
  final String primaryCurrency;
  final String secondaryCurrency;
  final Function(double) onSave;

  const RateCalculatorDialog({
    super.key,
    required this.currentRate,
    required this.primaryCurrency,
    required this.secondaryCurrency,
    required this.onSave,
  });

  @override
  State<RateCalculatorDialog> createState() => _RateCalculatorDialogState();
}

class _RateCalculatorDialogState extends State<RateCalculatorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rateController = TextEditingController();
  final _amountPrimaryController = TextEditingController(text: '1');
  final _amountSecondaryController = TextEditingController();

  double? _calculatedRate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.currentRate != null) {
      _rateController.text = widget.currentRate.toString();
    }

    _amountPrimaryController.addListener(_updateCalculatedRate);
    _amountSecondaryController.addListener(_updateCalculatedRate);
  }

  void _updateCalculatedRate() {
    final amount1 = double.tryParse(
      _amountPrimaryController.text.replaceAll(',', '.'),
    );
    final amount2 = double.tryParse(
      _amountSecondaryController.text.replaceAll(',', '.'),
    );

    if (amount1 != null && amount1 > 0 && amount2 != null && amount2 > 0) {
      setState(() {
        _calculatedRate = amount2 / amount1;
      });
    } else {
      setState(() {
        _calculatedRate = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rateController.dispose();
    _amountPrimaryController.dispose();
    _amountSecondaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Taux de conversion'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Saisie directe'),
                Tab(text: 'Calculatrice'),
              ],
            ),
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: Direct Rate
                  Center(
                    child: TextField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        labelText:
                            'Taux (1 ${widget.primaryCurrency} = ? ${widget.secondaryCurrency})',
                        suffixText: widget.secondaryCurrency,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  // TAB 2: Calculator
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountPrimaryController,
                                decoration: InputDecoration(
                                  labelText: widget.primaryCurrency,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(Icons.arrow_forward),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _amountSecondaryController,
                                decoration: InputDecoration(
                                  labelText: widget.secondaryCurrency,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_calculatedRate != null)
                          Text(
                            'Taux: ${_calculatedRate!.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          )
                        else
                          const Text(
                            'Saisissez les montants',
                            style: TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            double? finalRate;
            if (_tabController.index == 0) {
              // Direct entry
              finalRate = double.tryParse(
                _rateController.text.replaceAll(',', '.'),
              );
            } else {
              // Calculator
              finalRate = _calculatedRate;
            }

            if (finalRate != null && finalRate > 0) {
              widget.onSave(finalRate);
              Navigator.pop(context);
            }
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
