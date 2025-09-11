// 공용: 비행시간/직항셋/운임표/포맷터

const Map<String, int> kFlightTimes = {
  "TFU":245,"CAN":230,"CEB":270,"MNL":250,"NRT":140,"NGO":130,"KIX":110,"FUK":80,"CTS":165,"HKD":160,
  "FSZ":140,"HIJ":100,"MYJ":100,"OKA":130,"OIT":100,"KOJ":110,"CRK":260,"TAG":270,"HAN":270,"DAD":280,
  "CXR":300,"PQC":330,"VTE":300,"BKK":350,"CNX":340,"BKI":320,"SIN":390,"BTH":390,"DPS":420,"GUM":260,
  "SPN":270,"UBN":210,"MFM":225,"HKG":220,"TPE":160,"TAO":100,"YIH":210,"WEH":90,"KWL":240,"SJW":150,
  "JMU":150,"HRB":130,"RGN":360,"YTY":150,"PVG":120,"DFW":780,"YYZ":810,"YVR":600,"YUL":810,"KHH":190,
  "SGN":320,"KMI":110,"CDG":750,"AMS":720,"HND":130,"PUS":60,"SYD":600,"BNE":570,"TAE":60,"DEL":450,
  "MEX":900,"LAX":690,"KWE":240,"MAD":790,"HNL":540,"DOH":630,"HEL":600,"KIJ":130,"OKJ":100,"MXP":740,
  "FCO":750,"BWN":330,"TAS":410,"PEK":130,"PKX":130,"HGH":150,"TSN":120,"WUX":140,"SZX":210,"CKG":220,
  "DLC":90,"WNZ":160,"TNA":140,"YNT":90,"JFK":840,"ALA":380,"NQZ":410,"CSX":190,"CGO":170,"CGQ":120,
  "SHE":110,"KUL":390,"ATL":870,"DTW":800,"MSP":760,"SLC":750,"LAS":720,"SEA":600,"BOS":810,"IAD":840,
  "SFO":660,"ORD":760,"AOJ":135,"KTI":330,"CGK":420,"KMJ":100,"HKT":360,"KMQ":120,"CIT":390,"DXB":570,
  "ADD":770,"AUH":580,"XIY":190,"TYN":170,"NKG":130,"HAK":250,"SYX":280,"XMN":220,"FOC":200,"HFE":170,
  "WUH":160,"KMG":260,"DYG":210,"RMQ":180,"AKL":690,"YYC":630,"SHI":140,"CMB":480,"KKJ":90,"KTM":380,
  "UKB":110,"NGS":100,"LHR":750,"ZRH":730,"LIS":820,"VIE":710,"FRA":690,"IST":660,"BUD":690,"PRG":700,
  "TOY":120,"MRS":780,"AGP":810,"DSN":180,"MUC":700,"TAK":110,"ISG":140,"TXN":160,"ENH":180,"WAW":690,
  "WRO":700,"SDJ":150,"UBJ":100,"AKJ":160,"YNZ":140,"BCN":780,"KLO":280,"DAT":170,"YGJ":110,"WUS":160,
  "CPH":690,"ASB":420,"HSG":90,"ZAG":710,"BSZ":420,"HPH":260,"DMK":350,"EWR":830,"ESB":670,"DAC":370,
  "PNH":330,"TKS":110,"OSL":1200
};

const Set<String> kNonstopFromICN = {
  "KIX","NRT","FUK","PVG","HKG","TAO","DAD","BKK","TPE","CXR","MNL","CTS","SIN","SGN","HAN","PEK","NGO",
  "GUM","UBN","CEB","DLC","LAX","OKA","PQC","CAN","YNJ","SHE","SZX","PUS","TSN","SFO","KUL","CNX","MFM",
  "DPS","YNT","BKI","TNA","JFK","HKT","NKG","SYD","HGH","CDG","HNL","YVR","FRA","KHH","PKX","SEA","ATL",
  "HND","CRK","IST","TAS","CGK","PNH","CGQ","SPN","WEH","HRB","MYJ","TAK","FSZ","RMQ","FCO","ALA","UKB",
  "YYZ","DFW","LHR","AMS","KMJ","DXB","KLO","KKJ","VTE","CSX","XIY","FOC","XMN","BCN","CKG","KMG","DOH",
  "WUH","ORD","PRG","HPH","KOJ","HEL","IAD","LAS","MEX","MSP","SLC","DTW","EWR","TAE","BOS","BNE","MUC",
  "YYC","DYG","ADD","DEL","WAW","ZRH","HFE","SHI","ISG","SDJ","YGJ","RGN","SJW","MAD","AKJ","OKJ","HKD",
  "VIE","YUL","DMK","AKL","HAK","MXP","HSG","BUD","KMQ","LIS","KMI","NQZ","KIJ","WNZ","TKS","BWN","NGS",
  "AOJ","OIT","FRU","ZAG","DSN","YNZ","SYX","BTH","KTM","CIT","YTY","CMB","JMU","WRO","ASB","UBJ","HET","TFU"
};

const Map<String, Map<String, Map<String, int>>> kFareTable = {
  "단거리": {
    "비수기": {"이코노미": 105000, "프리미엄이코노미": 171750, "비즈니스": 330000, "퍼스트": 864000},
    "성수기": {"이코노미": 210000, "프리미엄이코노미": 343500, "비즈니스": 660000, "퍼스트": 1728000},
  },
  "중거리": {
    "비수기": {"이코노미": 105000, "프리미엄이코노미": 171750, "비즈니스": 330000, "퍼스트": 864000},
    "성수기": {"이코노미": 150000, "프리미엄이코노미": 217500, "비즈니스": 300000, "퍼스트": 960000},
  },
  "장거리": {
    "비수기": {"이코노미": 600000, "프리미엄이코노미": 985000, "비즈니스": 1900000, "퍼스트": 5000000},
    "성수기": {"이코노미": 925000, "프리미엄이코노미": 1523750, "비즈니스": 2950000, "퍼스트": 7800000},
  },
};

String classifyDistance(int mins) {
  if (mins <= 180) return "단거리";
  if (mins <= 420) return "중거리";
  return "장거리";
}

int fareOf(String distance, String season, String cls) =>
    kFareTable[distance]?[season]?[cls] ?? 0;

String fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String fmtTimeHM(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String fmtHHMMFromMinutes(int mins) {
  final h = mins ~/ 60, m = mins % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}