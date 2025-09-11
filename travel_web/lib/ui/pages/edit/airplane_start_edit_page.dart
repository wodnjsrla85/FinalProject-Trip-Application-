import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../data/airplane_start_repository.dart';
import '../../../utils/flight_meta.dart';

class AirplaneStartEditPage extends StatefulWidget {
  final String docId;
  const AirplaneStartEditPage({super.key, required this.docId});

  @override
  State<AirplaneStartEditPage> createState() => _AirplaneStartEditPageState();
}

class _AirplaneStartEditPageState extends State<AirplaneStartEditPage> {
  final _repo = AirplaneStartRepository();
  final _formKey = GlobalKey<FormState>();

  final _flightNo = TextEditingController();
  final _airline = TextEditingController();
  final _aircraft = TextEditingController();
  final _origin = TextEditingController(text: 'ICN'); // 고정
  final _destination = TextEditingController();
  final _terminal = TextEditingController(text: 'T1');
  final _totalSeats = TextEditingController();

  DateTime? _flightDate;
  TimeOfDay? _depTime;
  DateTime? _arrivalDateTime;

  bool loading = true;
  bool saving = false;

  // ===== 자동완성 후보(IATA) =====
  List<String> get _iataOptions {
    final set = {...kFlightTimes.keys, ...kNonstopFromICN};
    final list = set.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    try {
      final a = await _repo.fetchById(widget.docId);
      if (a == null) {
        setState(()=>loading=false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문서를 찾을 수 없습니다.')));
          Navigator.pop(context);
        }
        return;
      }
      _flightNo.text = a.flightNo;
      _airline.text = a.airline;
      _aircraft.text = a.aircraft;
      _origin.text = a.origin.isEmpty ? 'ICN' : a.origin; // 고정
      _destination.text = a.destination;
      _terminal.text = a.terminal;
      _totalSeats.text = a.totalSeats.toString();

      try { final p=a.flightDate.split('-'); _flightDate=DateTime(int.parse(p[0]),int.parse(p[1]),int.parse(p[2])); } catch(_){}
      try { final t=a.departureTime.split(':'); _depTime=TimeOfDay(hour:int.parse(t[0]),minute:int.parse(t[1])); } catch(_){}

      _recomputeArrival();
      setState(()=>loading=false);
    } catch (e) {
      setState(()=>loading=false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로드 실패: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _recomputeArrival() {
    if (_flightDate == null || _depTime == null) { _arrivalDateTime = null; return; }
    final dest = _destination.text.trim().toUpperCase();
    final minutes = kFlightTimes[dest];
    if (minutes == null) { _arrivalDateTime = null; return; }
    final dep = DateTime(_flightDate!.year, _flightDate!.month, _flightDate!.day, _depTime!.hour, _depTime!.minute);
    _arrivalDateTime = dep.add(Duration(minutes: minutes));
  }

  bool get _isDirect {
    final dest = _destination.text.trim().toUpperCase();
    return kNonstopFromICN.contains(dest);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _flightDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _flightDate = picked);
      _recomputeArrival();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _depTime ?? const TimeOfDay(hour: 9, minute: 0));
    if (picked != null) {
      setState(() => _depTime = picked);
      _recomputeArrival();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_flightDate == null || _depTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('출발 날짜/시간을 선택하세요.'))); return;
    }
    _recomputeArrival();
    if (_arrivalDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('도착 시간 계산 실패'))); return;
    }

    final dest = _destination.text.trim().toUpperCase();
    final mins = kFlightTimes[dest]!;
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

    setState(()=>saving=true);
    try {
      final data = <String, dynamic>{
        // Start 스키마(예시): start 쪽에서 쓰는 필드명과 일치시켜주세요.
        "운항편명": _flightNo.text.trim(),
        "항공사": _airline.text.trim(),
        "출발시간": depStrTime,
        "출발지": "ICN", // 고정
        "터미널": _terminal.text.trim(),
        "목적지": dest,
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
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('airplane_start')
          .doc(widget.docId)
          .set(data); // ✅ update() 대신 set()
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final arrivalDateStr = _arrivalDateTime == null ? '' : fmtDate(_arrivalDateTime!);
    final arrivalTimeStr = _arrivalDateTime == null ? '' : fmtTimeHM(_arrivalDateTime!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('출발편 수정'),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('저장'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(controller: _flightNo, decoration: const InputDecoration(labelText: '운항편명'), validator: (v)=> (v==null||v.trim().isEmpty)?'필수 입력':null,),
                TextFormField(controller: _airline, decoration: const InputDecoration(labelText: '항공사'), validator: (v)=> (v==null||v.trim().isEmpty)?'필수 입력':null,),
                TextFormField(controller: _aircraft, decoration: const InputDecoration(labelText: '기종')),
                const SizedBox(height: 12),

                Row(
                  children: [
                    // 출발지: ICN 고정
                    Expanded(
                      child: TextFormField(
                        controller: _origin,
                        readOnly: true,
                        enabled: false,
                        decoration: const InputDecoration(labelText: '출발지 (ICN)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 목적지: 자동완성 (여기가 핵심 변경)
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue v) {
                          final q = v.text.trim().toUpperCase();
                          if (q.isEmpty) return const Iterable<String>.empty();
                          return _iataOptions.where((opt) => opt.startsWith(q));
                        },
                        fieldViewBuilder: (context, textController, focusNode, _) {
                          // 최초 1회만 초기 동기화
                          if (textController.text.isEmpty && _destination.text.isNotEmpty) {
                            textController.text = _destination.text;
                            textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: textController.text.length),
                            );
                          }
                          return TextFormField(
                            controller: textController,
                            focusNode: focusNode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(labelText: '목적지 (IATA)'),
                            onChanged: (v) {
                              _destination.text = v.toUpperCase();
                              _recomputeArrival();
                              setState(() {});
                            },
                            validator: (v) {
                              final code = (v ?? '').trim().toUpperCase();
                              if (code.isEmpty) return '필수 입력';
                              if (!_iataOptions.contains(code)) return '알 수 없는 IATA 코드';
                              return null;
                            },
                          );
                        },
                        onSelected: (selection) {
                          _destination.text = selection.toUpperCase();
                          _recomputeArrival();
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),

                TextFormField(controller: _terminal, decoration: const InputDecoration(labelText: '터미널')),
                const SizedBox(height: 12),

                TextFormField(controller: _totalSeats, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '총좌석')),
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
                    Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('예상 도착일자(자동)'), subtitle: Text(arrivalDateStr))),
                    const SizedBox(width: 12),
                    Expanded(child: ListTile(contentPadding: EdgeInsets.zero, title: const Text('예상 도착시간(자동)'), subtitle: Text(arrivalTimeStr))),
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
                    onPressed: saving ? null : _save,
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