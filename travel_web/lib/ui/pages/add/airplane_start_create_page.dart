import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../utils/flight_meta.dart';

class AirplaneStartCreatePage extends StatefulWidget {
  const AirplaneStartCreatePage({super.key});

  @override
  State<AirplaneStartCreatePage> createState() => _AirplaneStartCreatePageState();
}

class _AirplaneStartCreatePageState extends State<AirplaneStartCreatePage> {
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final _flightNo = TextEditingController();
  final _airline = TextEditingController();
  final _aircraft = TextEditingController();
  final _origin = TextEditingController(text: 'ICN'); // 출발지 고정
  final _destination = TextEditingController();
  final _terminal = TextEditingController(text: 'T1');
  final _totalSeats = TextEditingController();

  DateTime? _flightDate;
  TimeOfDay? _depTime;
  DateTime? _arrivalDateTime;

  bool _saving = false;
  bool _recomputeScheduled = false;

  List<String> get _destOptions {
    final list = kFlightTimes.keys.toList()..sort();
    return list;
  }

  @override
  void dispose() {
    _flightNo.dispose();
    _airline.dispose();
    _aircraft.dispose();
    _origin.dispose();
    _destination.dispose();
    _terminal.dispose();
    _totalSeats.dispose();
    super.dispose();
  }

  void _scheduleRecompute() {
    if (_recomputeScheduled) return;
    _recomputeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _recomputeScheduled = false;
      setState(() => _computeArrivalPure());
    });
  }

  void _computeArrivalPure() {
    if (_flightDate == null || _depTime == null) {
      _arrivalDateTime = null;
      return;
    }
    final dst = _destination.text.trim().toUpperCase();
    final minutes = kFlightTimes[dst];
    if (minutes == null) {
      _arrivalDateTime = null;
      return;
    }
    final dep = DateTime(
      _flightDate!.year, _flightDate!.month, _flightDate!.day,
      _depTime!.hour, _depTime!.minute,
    );
    _arrivalDateTime = dep.add(Duration(minutes: minutes));
  }

  bool get _isDirect {
    final dst = _destination.text.trim().toUpperCase();
    return kNonstopFromICN.contains(dst);
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _flightDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _flightDate = picked);
      _scheduleRecompute();
    }
  }

  Future<void> _pickTime() async {
    final init = const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: _depTime ?? init,
    );
    if (picked != null) {
      setState(() => _depTime = picked);
      _scheduleRecompute();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_flightDate == null || _depTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('출발 날짜/시간을 선택하세요.')));
      return;
    }

    _computeArrivalPure();
    if (_arrivalDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('도착 시간 계산 실패')));
      return;
    }

    final dst = _destination.text.trim().toUpperCase();
    final mins = kFlightTimes[dst]!;
    final depStrDate = fmtDate(_flightDate!);
    final depStrTime = '${_depTime!.hour.toString().padLeft(2,'0')}:${_depTime!.minute.toString().padLeft(2,'0')}';
    final arrStrDate = fmtDate(_arrivalDateTime!);
    final arrStrTime = fmtTimeHM(_arrivalDateTime!);

    final isDirect = _isDirect;
    final directInt = isDirect ? 1 : 0;
    final directTxt = isDirect ? '직항' : '경유';
    final distanceGroup = classifyDistance(mins);

    final offEco   = fareOf(distanceGroup, "비수기", "이코노미");
    final offPrem  = fareOf(distanceGroup, "비수기", "프리미엄이코노미");
    final offBiz   = fareOf(distanceGroup, "비수기", "비즈니스");
    final offFirst = fareOf(distanceGroup, "비수기", "퍼스트");
    final peakEco  = fareOf(distanceGroup, "성수기", "이코노미");
    final peakPrem = fareOf(distanceGroup, "성수기", "프리미엄이코노미");
    final peakBiz  = fareOf(distanceGroup, "성수기", "비즈니스");
    final peakFirst= fareOf(distanceGroup, "성수기", "퍼스트");

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        "운항편명": _flightNo.text.trim(),
        "항공사": _airline.text.trim(),
        "출발시간": depStrTime,
        "출발지": _origin.text.trim(), // ICN
        "터미널": _terminal.text.trim(),
        "목적지": dst,
        "예상 소요 시간": mins,
        "직항여부": directInt,
        "직항/경유": directTxt,
        "상태": "운행",
        "기종": _aircraft.text.trim(),
        "총좌석": int.tryParse(_totalSeats.text.trim()) ?? 0,
        "운항일자": depStrDate,
        "예상 도착일자": arrStrDate,
        "예상 도착시간": arrStrTime,
        "예상 소요(hh:mm)": fmtHHMMFromMinutes(mins),
        "거리구분": distanceGroup,
        "비수기_이코노미_평균운임": offEco,
        "비수기_프리미엄이코노미_평균운임": offPrem,
        "비수기_비즈니스_평균운임": offBiz,
        "비수기_퍼스트_평균운임": offFirst,
        "성수기_이코노미_평균운임": peakEco,
        "성수기_프리미엄이코노미_평균운임": peakPrem,
        "성수기_비즈니스_평균운임": peakBiz,
        "성수기_퍼스트_평균운임": peakFirst,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('airplane_start').add(data);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrivalDateStr = _arrivalDateTime == null ? '' : fmtDate(_arrivalDateTime!);
    final arrivalTimeStr = _arrivalDateTime == null ? '' : fmtTimeHM(_arrivalDateTime!);

    final dst = _destination.text.trim().toUpperCase();
    final mins = kFlightTimes[dst];
    final durationHHMM = (mins == null) ? '' : fmtHHMMFromMinutes(mins);
    final distanceGroup = (mins == null) ? '' : classifyDistance(mins);

    return Scaffold(
      appBar: AppBar(
        title: const Text('출발편 추가'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _flightNo,
                  decoration: const InputDecoration(labelText: '운항편명 (예: KE123)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력' : null,
                ),
                TextFormField(
                  controller: _airline,
                  decoration: const InputDecoration(labelText: '항공사'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '필수 입력' : null,
                ),
                TextFormField(
                  controller: _aircraft,
                  decoration: const InputDecoration(labelText: '기종 (예: Boeing 777)'),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _origin,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(labelText: '출발지 (ICN)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final q = textEditingValue.text.trim().toUpperCase();
                          if (q.isEmpty) return const Iterable<String>.empty();
                          return _destOptions.where((opt) => opt.startsWith(q));
                        },
                        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: '목적지 (IATA, 예: NRT)'),
                            onChanged: (v) {
                              _destination.text = v.toUpperCase();
                              _scheduleRecompute();
                            },
                            validator: (v) {
                              final code = (v ?? '').trim().toUpperCase();
                              if (code.isEmpty) return '필수 입력';
                              if (!kFlightTimes.containsKey(code)) return '알 수 없는 공항 코드입니다.';
                              return null;
                            },
                          );
                        },
                        onSelected: (String selection) {
                          _destination.text = selection.toUpperCase();
                          _scheduleRecompute();
                        },
                      ),
                    ),
                  ],
                ),

                TextFormField(
                  controller: _terminal,
                  decoration: const InputDecoration(labelText: '터미널 (예: T1, T2)'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _totalSeats,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '총좌석'),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('운항일자'),
                        subtitle: Text(_flightDate == null ? '' : fmtDate(_flightDate!)),
                        trailing: TextButton(onPressed: _pickDate, child: const Text('선택')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('출발시간'),
                        subtitle: Text(_depTime == null ? '' : '${_depTime!.hour.toString().padLeft(2,'0')}:${_depTime!.minute.toString().padLeft(2,'0')}'),
                        trailing: TextButton(onPressed: _pickTime, child: const Text('선택')),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('예상 도착일자(자동)'),
                        subtitle: Text(arrivalDateStr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('예상 도착시간(자동)'),
                        subtitle: Text(arrivalTimeStr),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('예상 소요(hh:mm)'),
                        subtitle: Text(durationHHMM),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('거리구분'),
                        subtitle: Text(distanceGroup),
                      ),
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24),
                    child: Text('항로: ${_isDirect ? "직항" : "경유"}'),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}