import 'package:flutter/material.dart';

import 'brand.dart';
import 'crop_catalog.dart';
import 'theme.dart';

class DiseaseLibraryScreen extends StatefulWidget {
  final String lang;
  final String? initialCrop;

  const DiseaseLibraryScreen({
    super.key,
    required this.lang,
    this.initialCrop,
  });

  @override
  State<DiseaseLibraryScreen> createState() => _DiseaseLibraryScreenState();
}

class _DiseaseLibraryScreenState extends State<DiseaseLibraryScreen> {
  late String _crop;

  @override
  void initState() {
    super.initState();
    _crop = widget.initialCrop ?? 'All';
  }

  String ui(String en, String sn, String nd, String toi) {
    switch (widget.lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }

  String cropLabel(String crop) {
    if (crop == 'All') {
      return ui('All', 'Zvose', 'Konke', 'Zyoonse');
    }
    return cropById(crop)?.label(widget.lang) ?? crop;
  }

  @override
  Widget build(BuildContext context) {
    final items = _crop == 'All'
        ? diseaseLibrary
        : diseaseLibrary.where((d) => d.crop == _crop).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Expanded(child: CropMedicBrand(compact: true, showTagline: false)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    ui('Crop library', 'Raibhurari yezvirimwa', 'Umtapo wezilimo', 'Layiburari yamilimo'),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: Palette.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ui(
                      'Learn common symptoms, spread, first steps and prevention for crops currently supported by CropMedic AI.',
                      'Dzidza zviratidzo, kupararira, zvekutanga kuita uye kudzivirira pazvirimwa zvinotsigirwa neCropMedic AI.',
                      'Funda izimpawu, ukusabalala, okokuqala ukukwenza lokuvikela ezilimweni ezisekelwa yiCropMedic AI.',
                      'Ziba zibonakaliso, kuzwidila, zyakutanguna kucita akuzwidilila kumilimo ilagwasigwa neCropMedic AI.',
                    ),
                    style: const TextStyle(color: Palette.textDim, fontSize: 15.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', ...supportedCrops.map((c) => c.id)]
                        .map((crop) => ChoiceChip(
                              label: Text(cropLabel(crop)),
                              selected: _crop == crop,
                              onSelected: (_) => setState(() => _crop = crop),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  ...items.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showDisease(d),
                          borderRadius: BorderRadius.circular(22),
                          child: AppCard(
                            padding: const EdgeInsets.all(14),
                            radius: 22,
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Palette.primarySoft,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(cropById(d.crop)?.emoji ?? '🌿', style: const TextStyle(fontSize: 28)),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cropLabel(d.crop), style: const TextStyle(color: Palette.textDim, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        d.name.text(widget.lang),
                                        style: const TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Palette.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        d.shortSymptom.text(widget.lang),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12.5, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Palette.primary),
                              ],
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  AppCard(
                    color: const Color(0xFFF2F6EE),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ui('More crops are being added', 'Zvimwe zvirimwa zviri kuwedzerwa', 'Ezinye izilimo ziyengezwa', 'Milimo imwi ilakuboolesigwa'),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Palette.primaryDark),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: roadmapCrops
                              .map((crop) => Chip(label: Text('${crop.emoji} ${crop.label(widget.lang)}')))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ui(
                            'They are not shown as diagnosable yet because each crop needs training data and field validation first.',
                            'Hazvisati zvichionekwa sezvinogona kuongororwa nekuti chirimwa chimwe nechimwe chinoda data yekudzidzisa nekuyedzwa muminda.',
                            'Azikaboniswa njengezingahlolwa ngoba isilimo ngasinye sidinga idatha yokuqeqetsha lokuhlolwa emasimini.',
                            'Tazilatondezyi kuti zilayandulwa nkaambo mulimo omweomwe ulacida data akuyesya muminda.',
                          ),
                          style: const TextStyle(color: Palette.textDim, fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5DE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      ui(
                        'General guidance only. For severe or spreading disease, confirm treatment with a qualified extension officer or registered agro-dealer.',
                        'Aya mazano akajairika chete. Kana chirwere chakanyanya kana kupararira, simbisa kurapwa neextension officer kana agro-dealer akanyoreswa.',
                        'Lesi yiseluleko esijwayelekileyo kuphela. Nxa isifo sinzima kumbe sisabalala, qinisekisa ukwelatshwa lesiphathamandla se-extension kumbe i-agro-dealer ebhalisiweyo.',
                        'Aaya malayilile aajwayelekile alikke. Naa bulwazi buli buyumu naa bulazwidila, sinizya bulapi kumugwasyi wabalimi naa agro-dealer wasinizidwe.',
                      ),
                      style: const TextStyle(fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDisease(DiseaseInfo d) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .82,
        minChildSize: .55,
        maxChildSize: .94,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(color: Palette.border, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 18),
            Text(cropLabel(d.crop), style: const TextStyle(color: Palette.textDim, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              d.name.text(widget.lang),
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Palette.primaryDark,
              ),
            ),
            const SizedBox(height: 18),
            _section(ui('What to look for', 'Zvekutarisa', 'Okumele ukubone', 'Zyakulanga'), d.symptoms),
            _section(ui('What helps it spread', 'Zvinobatsira kupararira', 'Okusiza ukusabalala', 'Zyigwasya kuzwidila'), d.spread),
            _section(ui('What to do now', 'Zvekuita izvozvi', 'Okumele ukwenze khathesi', 'Zyakucita lino'), d.actions),
            _section(ui('Prevention', 'Kudzivirira', 'Ukuvikela', 'Kuzwidilila'), d.prevention),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<LT> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Palette.primaryDark)),
            const SizedBox(height: 10),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: CircleAvatar(radius: 3, backgroundColor: Palette.primary),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(line.text(widget.lang), style: const TextStyle(height: 1.4))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LT {
  final String en;
  final String sn;
  final String nd;
  final String toi;

  const LT(this.en, this.sn, this.nd, this.toi);

  String text(String lang) {
    switch (lang) {
      case 'sn': return sn;
      case 'nd': return nd;
      case 'toi': return toi;
      default: return en;
    }
  }
}

class DiseaseInfo {
  final String crop;
  final LT name;
  final LT shortSymptom;
  final List<LT> symptoms;
  final List<LT> spread;
  final List<LT> actions;
  final List<LT> prevention;

  const DiseaseInfo({
    required this.crop,
    required this.name,
    required this.shortSymptom,
    required this.symptoms,
    required this.spread,
    required this.actions,
    required this.prevention,
  });
}

const diseaseLibrary = <DiseaseInfo>[
  DiseaseInfo(
    crop: 'Maize',
    name: LT('Northern Leaf Blight', 'Northern Leaf Blight', 'Northern Leaf Blight', 'Northern Leaf Blight'),
    shortSymptom: LT('Long grey-green to tan lesions that expand along the leaf.', 'Mavanga marefu egrey-green kusvika brown anokura achitevedza shizha.', 'Amabala amade aluhlaza-grey aze abe nsundu aqhubeka eceleni kweqabunga.', 'Mabala maleele a grey-green kusika kubrown alakula ashika mubbazu lyashizha.'),
    symptoms: [
      LT('Long cigar-shaped lesions on leaves.', 'Mavanga marefu akaita secigar pamashizha.', 'Amabala amade afana le-cigar emaqabungeni.', 'Mabala maleele aali mbuli cigar amashizha.'),
      LT('Older lower leaves are often affected first.', 'Mashizha ekare ari pasi ndiwo anowanzotanga kubatwa.', 'Amaqabunga amadala angaphansi ajayele ukuqala ukuthinteka.', 'Mashizha aakale aansi ngaajanwa kutanga.'),
      LT('Severe infection can dry large parts of the leaf.', 'Kana chirwere chakanyanya chinogona kuomesa chikamu chikuru cheshizha.', 'Ukutheleleka okukhulu kungomisa ingxenye enkulu yeqabunga.', 'Bulwazi buyumu bulakomesya cibeela cipati cashizha.'),
    ],
    spread: [
      LT('Warm, humid weather and long periods of leaf wetness.', 'Kupisa, humidity yakakwira uye mashizha kugara akanyorova kwenguva refu.', 'Isimo esifudumele esile-humidity kanye lamaqabunga ahlala emanzi isikhathi eside.', 'Mvula iipya iile humidity amashada azizilila manzi kwaciindi.'),
      LT('Infected crop residue can carry disease between seasons.', 'Masara ezvirimwa ane chirwere anogona kuchengeta chirwere kubva mumwaka kuenda kune unotevera.', 'Insalela zezilimo ezithelelekileyo zingathwala isifo phakathi kweminyaka yokulima.', 'Masala aamilimo ajatwa alakweenda abulwazi kumwaka umwi.'),
    ],
    actions: [
      LT('Remove badly affected leaves where practical.', 'Bvisa mashizha akabatwa zvakanyanya kana zvichikwanisika.', 'Susa amaqabunga athinteke kakhulu nxa kungenzeka.', 'Bweza mashizha ajatwa kapati naa kulakonzya.'),
      LT('Avoid overhead irrigation late in the day.', 'Usadiridzire pamusoro pemashizha manheru.', 'Gwema ukunisela phezu kwamahlamvu ntambama.', 'Tandika kudilila ansengwe amashizha kumamanino amazuba.'),
      LT('Ask an extension officer or agro-dealer before choosing a fungicide.', 'Bvunza extension officer kana agro-dealer usati wasarudza fungicide.', 'Buza isiphathamandla se-extension kumbe i-agro-dealer ungakakhethi i-fungicide.', 'Buzya mugwasyi wabalimi naa agro-dealer inga kusalwe fungicide.'),
    ],
    prevention: [
      LT('Rotate maize with non-host crops.', 'Chinjanisa chibage nezvimwe zvirimwa zvisingatapukirwi nechirwere ichi.', 'Tshintshanisa umumbu lezilimo ezingathwali lesi sifo.', 'Cinjanya maize amilimo itajatwi abulwazi oobu.'),
      LT('Manage infected crop residue.', 'Chenesa kana gadzirisa masara ezvirimwa ane chirwere.', 'Phatha kuhle insalela zezilimo ezithelelekileyo.', 'Longa masala aamilimo ajatwa.'),
      LT('Use tolerant varieties where available.', 'Shandisa mhando dzinoshingirira kana dziripo.', 'Sebenzisa izinhlobo ezimelana lesifo nxa zikhona.', 'Belensya mikowa ilakonzya kulwana abulwazi naa ijanika.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Maize',
    name: LT('Common Rust', 'Common Rust', 'Common Rust', 'Common Rust'),
    shortSymptom: LT('Small cinnamon-brown raised pustules on both leaf surfaces.', 'Mapundu madiki ebrown akasimuka pamativi ose eshizha.', 'Amaqhubu amancane ansundu aphakemeyo emaceleni womabili eqabunga.', 'Mapundu masyoonto abrown aasimuka kumbazu zyobile zyashizha.'),
    symptoms: [
      LT('Small raised reddish-brown pustules.', 'Mapundu madiki reddish-brown akasimuka.', 'Amaqhubu amancane abomvu-nsundu aphakemeyo.', 'Mapundu masyoonto a reddish-brown aasimuka.'),
      LT('Pustules may appear on both sides of the leaf.', 'Mapundu anogona kuoneka pamativi ose eshizha.', 'Amaqhubu angavela emaceleni womabili eqabunga.', 'Mapundu alakuboneka kumbazu zyobile zyashizha.'),
      LT('Heavy infection can reduce green leaf area.', 'Chirwere chakanyanya chinoderedza chikamu cheshizha chine hutano.', 'Ukutheleleka okukhulu kwehlisa indawo eluhlaza yeqabunga.', 'Bulwazi buyumu bulasyoosya cibeela cipona cashizha.'),
    ],
    spread: [
      LT('Cool to moderate temperatures with moisture.', 'Mamiriro anotonhorera kusvika pakati pamwe nehunyoro.', 'Amazinga apholileyo aze abe phakathi elomswakama.', 'Mvula itontola kusika pakati aamanzi.'),
      LT('Spores move easily by wind.', 'Spores dzinofamba nyore nemhepo.', 'Ama-spore ahamba lula ngomoya.', 'Ma-spore alafambiswa lyuwo.'),
    ],
    actions: [
      LT('Monitor spread across the field.', 'Ramba uchitarisa kuti chirwere chiri kupararira sei mumunda.', 'Qhubeka uhlola ukusabalala ensimini.', 'Langa kuzwidila kwabuzwayi mumunda.'),
      LT('Do not remove healthy leaves unnecessarily.', 'Usabvisa mashizha ane hutano zvisina basa.', 'Ungasusi amaqabunga aphilileyo kungadingekile.', 'Utabwezi mashizha apona kunyina.'),
      LT('Seek local advice if infection is severe early in crop growth.', 'Tsvaga mazano emunharaunda kana chirwere chakanyanya chirimwa chichiri chidiki.', 'Dinga iseluleko sendawo nxa isifo sinzima isilimo sisakhula.', 'Jana malayilile naa bulwazi buyumu mulimo ucili muniini.'),
    ],
    prevention: [
      LT('Use resistant varieties where suitable.', 'Shandisa mhando dzinoramba chirwere kana dzakakodzera.', 'Sebenzisa izinhlobo ezimelana lesifo lapho kufanele.', 'Belensya mikowa ilwana abulwazi naa yakatondeka.'),
      LT('Plant on time for the local season.', 'Dyara nenguva yakakodzera yemwaka wenzvimbo yako.', 'Hlanyela ngesikhathi esifaneleyo sendawo yakho.', 'Byala muciindi cakazulilwe cibalo cako.'),
      LT('Keep fields well balanced nutritionally.', 'Chengetedza chikafu chezvirimwa chakaenzana mumunda.', 'Gcina ukudla kwezitshalo kulingana ensimini.', 'Sinizya mulimo ulajana zyoonse zyakulya zyakweelela.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Maize',
    name: LT('Gray Leaf Spot', 'Gray Leaf Spot', 'Gray Leaf Spot', 'Gray Leaf Spot'),
    shortSymptom: LT('Rectangular grey or tan lesions running between leaf veins.', 'Mavanga ane rectangular shape egrey kana tan ari pakati petsinga dzeshizha.', 'Amabala ayizikwele amhlophe-grey kumbe tan aphakathi kwemithambo yeqabunga.', 'Mabala a rectangular a grey naa tan ali akati kamitanga yashizha.'),
    symptoms: [
      LT('Small rectangular spots that become grey or tan.', 'Mavanga madiki rectangular anozova grey kana tan.', 'Amabala amancane ayizikwele aba grey kumbe tan.', 'Mabala masyoonto a rectangular aba grey naa tan.'),
      LT('Lesions are usually limited by leaf veins.', 'Mavanga anowanzo gumira pakati petsinga dzeshizha.', 'Amabala ajayele ukuma phakathi kwemithambo yeqabunga.', 'Mabala aama akati kamitanga yashizha.'),
      LT('Many lesions can join together and dry the leaf.', 'Mavanga mazhinji anogona kubatana akaomesa shizha.', 'Amabala amanengi angahlangana omise iqabunga.', 'Mabala manjimya alakubambanana akomesye shizha.'),
    ],
    spread: [
      LT('High humidity and frequent rain.', 'Humidity yakakwira nemvura inonaya kakawanda.', 'I-humidity ephezulu lemvula ejayelekileyo.', 'Humidity yapati amvula njinjisya.'),
      LT('Continuous maize and infected residues increase pressure.', 'Kurima chibage nguva dzose pamwe nemasara ane chirwere kunowedzera dambudziko.', 'Ukulima umumbu njalo lensalela ezithelelekileyo kwandisa ingcindezi yesifo.', 'Kubyalwa maize lyoonse amasala ajatwa kulasumpula bulwazi.'),
    ],
    actions: [
      LT('Scout lower and middle leaves regularly.', 'Tarisa mashizha epasi nepakati nguva dzose.', 'Hlola amaqabunga aphansi laphakathi njalo.', 'Langa mashizha aansi aakati lyoonse.'),
      LT('Improve airflow where crop is very dense.', 'Wedzera kufamba kwemhepo kana zvirimwa zvakawandisa.', 'Thuthukisa ukuhamba komoya lapho isilimo siminyene.', 'Gwasyilizya kuzyunguluka kwamuuwo naa mulimo wajanikana kapati.'),
      LT('Confirm treatment need with an extension professional.', 'Simbisa kurapwa kunodiwa neextension professional.', 'Qinisekisa ukwelatshwa okudingekayo lesiphathamandla se-extension.', 'Sinizya bulapi abamugwasyi wabalimi.'),
    ],
    prevention: [
      LT('Rotate crops.', 'Chinjanisa zvirimwa.', 'Tshintshanisa izilimo.', 'Cinjanya milimo.'),
      LT('Use tolerant hybrids.', 'Shandisa hybrids dzinoshingirira.', 'Sebenzisa ama-hybrid amelana lesifo.', 'Belensya ma-hybrid alakonzya kulwana abulwazi.'),
      LT('Manage residues after harvest.', 'Chenesa masara mushure mekukohwa.', 'Phatha insalela ngemva kokuvuna.', 'Longa masala mwamana kuuna.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Tomato',
    name: LT('Early Blight', 'Early Blight', 'Early Blight', 'Early Blight'),
    shortSymptom: LT('Brown spots with concentric rings, often on older lower leaves.', 'Mavanga ebrown ane maringi, kazhinji pamashizha ekare epasi.', 'Amabala ansundu alemiringi, ajayele ukuba emaqabungeni amadala aphansi.', 'Mabala abrown aale miringi, njinjisya amashizha aakale aansi.'),
    symptoms: [
      LT('Dark brown leaf spots with target-like rings.', 'Mavanga dark brown ane maringi akaita setarget.', 'Amabala amnyama-nsundu alemiringi efana le-target.', 'Mabala a dark brown aale miringi mbuli target.'),
      LT('Yellowing around lesions.', 'Kuita yellow kutenderedza mavanga.', 'Ukuba yellow eduze kwamabala.', 'Kuba yellow mumbali yamabala.'),
      LT('Lower leaves often show symptoms first.', 'Mashizha epasi ndiwo anowanzotanga kuratidza zviratidzo.', 'Amaqabunga aphansi ajayele ukuqala ukukhombisa izimpawu.', 'Mashizha aansi ngaajanwa kutanga.'),
    ],
    spread: [
      LT('Warm weather, splashing water and infected debris.', 'Kupisa, mvura inosasa uye masara ane chirwere.', 'Isimo esifudumele, amanzi aqhulayo lensalela ezithelelekileyo.', 'Mvula iipya, manzi asapazika amasala ajatwa.'),
      LT('Plant stress can increase severity.', 'Kushushikana kwechirimwa kunogona kuwedzera chirwere.', 'Ukucindezeleka kwesitshalo kungandisa ubunzima besifo.', 'Kulemwa kwamulimo kulasumpula bulwazi.'),
    ],
    actions: [
      LT('Remove badly infected lower leaves.', 'Bvisa mashizha epasi akabatwa zvakanyanya.', 'Susa amaqabunga aphansi atheleleke kakhulu.', 'Bweza mashizha aansi ajatwa kapati.'),
      LT('Water at soil level rather than wetting foliage.', 'Diridza pasi kwete kunyorovesa mashizha.', 'Nisela emhlabathini hatshi phezu kwamahlamvu.', 'Dilila ansi kutali ansengwe mashizha.'),
      LT('Keep diseased leaves out of the growing area.', 'Bvisa mashizha ane chirwere munzvimbo yekurima.', 'Susa amaqabunga agulayo endaweni yokulima.', 'Bweza mashizha alabulwazi mumbali yamunda.'),
    ],
    prevention: [
      LT('Rotate tomatoes with unrelated crops.', 'Chinjanisa madomasi nezvimwe zvirimwa zvisiri mumhuri imwe.', 'Tshintshanisa utamatisi lezilimo ezingahlobani lawo.', 'Cinjanya tomato amilimo itabambiki nayo.'),
      LT('Stake or space plants to improve airflow.', 'Isa spacing yakanaka kana kutsigira zvirimwa kuti mhepo ifambe.', 'Faka isikhala esihle kumbe usekele izitshalo ukuze umoya uhambe.', 'Siyanya milimo kuti muuwo weende kabotu.'),
      LT('Use clean seedlings and avoid working wet plants.', 'Shandisa seedlings dzakachena uye usashanda zvirimwa zvakanyorova.', 'Sebenzisa izithombo ezihlanzekileyo njalo ungasebenzi izitshalo ezimanzi.', 'Belensya seedlings zicena utabeleki milimo imanzi.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Tomato',
    name: LT('Late Blight', 'Late Blight', 'Late Blight', 'Late Blight'),
    shortSymptom: LT('Fast-spreading dark water-soaked patches, especially in cool wet weather.', 'Mavanga dark akaita semvura anokurumidza kupararira, kunyanya kuchitonhora uye kwakanyorova.', 'Amabala amnyama amanzi asabalala masinya, ikakhulu lapho kupholile kumanzi.', 'Mabala masiita amanzi alazwidila cakufwamba, kapati naa kwatontola akunyowa.'),
    symptoms: [
      LT('Irregular dark water-soaked lesions.', 'Mavanga dark asina shape yakafanana akaita semvura.', 'Amabala amnyama angalinganiyo abonakala emanzi.', 'Mabala masiita amanzi atalingani.'),
      LT('White growth may appear on leaf undersides in humid conditions.', 'White growth inogona kuoneka pasi pemashizha kana humidity yakakwira.', 'Ukukhula okumhlophe kungabonakala ngaphansi kwamaqabunga lapho ku-humid.', 'Bintu zicituba zilakuboneka ansi amashizha naa humidity yapati.'),
      LT('Leaves and stems can collapse quickly.', 'Mashizha nemadzinde zvinogona kukurumidza kuora kana kuwira.', 'Amaqabunga leziqu kungawa masinya.', 'Mashizha amisinde alakubonongeka cakufwamba.'),
    ],
    spread: [
      LT('Cool wet weather and prolonged leaf wetness.', 'Kutonhora, kunyorova uye mashizha kugara akanyorova kwenguva refu.', 'Isimo esipholileyo esimanzi lamaqabunga ahlala emanzi isikhathi eside.', 'Mvula itontola imanzi amashizha azizilila manzi kwaciindi.'),
      LT('Wind-blown spores can move between fields.', 'Spores dzinofambiswa nemhepo kubva mumunda kuenda kune mumwe.', 'Ama-spore ahanjiswa ngumoya phakathi kwamasimu.', 'Ma-spore alaendesigwa lyuwo pakati kaminda.'),
    ],
    actions: [
      LT('Separate severely affected plants where practical.', 'Patsanura zvirimwa zvakabatwa zvakanyanya kana zvichikwanisika.', 'Hlukanisa izitshalo ezithinteke kakhulu nxa kungenzeka.', 'Siyanya milimo yajatwa kapati naa kulakonzya.'),
      LT('Avoid moving through wet crops.', 'Usafamba-fambe muzvirimwa zvakanyorova.', 'Gwema ukuhamba phakathi kwezitshalo ezimanzi.', 'Tandika kwenda pakati kamilimo imanzi.'),
      LT('Seek extension advice quickly because late blight can spread fast.', 'Tsvaga extension advice nekukurumidza nekuti late blight inopararira nekukurumidza.', 'Dinga iseluleko se-extension masinya ngoba late blight isabalala masinya.', 'Jana malayilile cakufwamba nkaambo late blight ilazwidila cakufwamba.'),
    ],
    prevention: [
      LT('Use clean planting material.', 'Shandisa mbeu kana material yekudyara yakachena.', 'Sebenzisa impahla yokuhlanyela ehlanzekileyo.', 'Belensya zyabyalo zicena.'),
      LT('Avoid overhead irrigation where possible.', 'Usadiridzire pamusoro pemashizha kana zvichikwanisika.', 'Gwema ukunisela phezu kwamahlamvu nxa kungenzeka.', 'Tandika kudilila ansengwe mashizha naa kulakonzya.'),
      LT('Destroy infected volunteer plants and crop debris.', 'Bvisa zvirimwa zvinomera zvega zvine chirwere nemasara.', 'Bulala izitshalo ezimila zodwa ezithelelekileyo lensalela.', 'Bweza milimo imela yoonse yajatwa amasala.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Tomato',
    name: LT('Septoria Leaf Spot', 'Septoria Leaf Spot', 'Septoria Leaf Spot', 'Septoria Leaf Spot'),
    shortSymptom: LT('Many small circular spots with pale centres and dark margins.', 'Mavanga madiki akawanda eround ane pakati pakachena nemicheto dark.', 'Amabala amanengi amancane ayindilinga aphakathi akhanyayo lemiphetho emnyama.', 'Mabala manjimya masyoonto azunguluka ali pakati pacena amumbali mnyama.'),
    symptoms: [
      LT('Numerous small round spots on lower leaves.', 'Mavanga madiki eround akawanda pamashizha epasi.', 'Amabala amanengi amancane ayindilinga emaqabungeni aphansi.', 'Mabala manjimya masyoonto azunguluka amashizha aansi.'),
      LT('Spots often have grey centres with dark borders.', 'Mavanga anowanzova nepakati pegrey nemicheto dark.', 'Amabala ajayele ukuba laphakathi okungu-grey lemiphetho emnyama.', 'Mabala ajayele kuba pakati grey amumbali mnyama.'),
      LT('Affected leaves yellow and may drop.', 'Mashizha akabatwa anoita yellow uye anogona kudonha.', 'Amaqabunga athintekileyo aba yellow njalo angawa.', 'Mashizha ajatwa aba yellow alakubwa.'),
    ],
    spread: [
      LT('Rain splash, overhead watering and infected debris.', 'Mvura inosasa, kudiridza pamusoro uye masara ane chirwere.', 'Ukutshaya kwemvula, ukunisela phezu kwamahlamvu lensalela ezithelelekileyo.', 'Kupazika kwamvula, kudilila ansengwe amashizha amasala ajatwa.'),
      LT('Warm humid conditions favour infection.', 'Kupisa uye humidity yakakwira zvinobatsira chirwere.', 'Isimo esifudumele esile-humidity sithanda lesi sifo.', 'Mvula iipya iile humidity ilagwasya bulwazi.'),
    ],
    actions: [
      LT('Remove heavily spotted lower leaves.', 'Bvisa mashizha epasi ane mavanga mazhinji.', 'Susa amaqabunga aphansi alamabala amanengi.', 'Bweza mashizha aansi aale mabala manjimya.'),
      LT('Water at the base of plants.', 'Diridza pazasi pechirimwa.', 'Nisela phansi kwesitshalo.', 'Dilila ansi amulimo.'),
      LT('Keep foliage dry when possible.', 'Chengetedza mashizha akaoma kana zvichikwanisika.', 'Gcina amaqabunga omile nxa kungenzeka.', 'Sinizya amashizha auma naa kulakonzya.'),
    ],
    prevention: [
      LT('Rotate crops and clean up residues.', 'Chinjanisa zvirimwa uye chenesa masara.', 'Tshintshanisa izilimo njalo uhlanze insalela.', 'Cinjanya milimo akucenesa masala.'),
      LT('Space plants for airflow.', 'Siya spacing kuti mhepo ifambe.', 'Faka izikhala ukuze umoya uhambe.', 'Siyanya milimo kuti muuwo weende.'),
      LT('Avoid handling plants when leaves are wet.', 'Usabata zvirimwa kana mashizha akanyorova.', 'Gwema ukuphatha izitshalo lapho amaqabunga emanzi.', 'Tandika kubamba milimo naa mashizha manyowa.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Potato',
    name: LT('Early Blight', 'Early Blight', 'Early Blight', 'Early Blight'),
    shortSymptom: LT('Brown target-like spots on older leaves with yellowing around them.', 'Mavanga ebrown akaita setarget pamashizha ekare ane yellow kutenderedza.', 'Amabala ansundu afana le-target emaqabungeni amadala ale-yellow eduze kwawo.', 'Mabala abrown mbuli target amashizha aakale aale yellow mumbali.'),
    symptoms: [
      LT('Concentric-ring lesions on older leaves.', 'Mavanga ane maringi pamashizha ekare.', 'Amabala alemiringi emaqabungeni amadala.', 'Mabala aale miringi amashizha aakale.'),
      LT('Yellow tissue around spots.', 'Chikamu cheyellow chakatenderedza mavanga.', 'Izicubu ezi-yellow ezungeze amabala.', 'Cibeela ci-yellow mumbali yamabala.'),
      LT('Severe disease causes premature leaf loss.', 'Chirwere chakanyanya chinodonhedza mashizha nguva isati yakwana.', 'Isifo esinzima sibangela ukuwa kwamaqabunga masinya.', 'Bulwazi buyumu bulakubusya mashizha ciindi cisanafika.'),
    ],
    spread: [
      LT('Warm conditions, moisture and plant stress.', 'Kupisa, hunyoro uye kushushikana kwechirimwa.', 'Isimo esifudumele, umswakama lokucindezeleka kwesitshalo.', 'Mvula iipya, kunyowa akulemwa kwamulimo.'),
      LT('Infected residues can carry disease.', 'Masara ane chirwere anogona kuchengeta chirwere.', 'Insalela ezithelelekileyo zingathwala isifo.', 'Masala ajatwa alatola bulwazi.'),
    ],
    actions: [
      LT('Remove heavily infected foliage where practical.', 'Bvisa mashizha akabatwa zvakanyanya kana zvichikwanisika.', 'Susa amaqabunga atheleleke kakhulu nxa kungenzeka.', 'Bweza mashizha ajatwa kapati naa kulakonzya.'),
      LT('Reduce plant stress through good watering and nutrition.', 'Deredza kushushikana kwechirimwa nekudiridza nekuchipa chikafu zvakanaka.', 'Yehlisa ukucindezeleka ngokunisela kuhle lokunika ukudla okufaneleyo.', 'Syoosya kulemwa kwamulimo akudilila akupa zyakulya kabotu.'),
      LT('Confirm fungicide decisions locally.', 'Simbisa kusarudzwa kwefungicide nemazano emunharaunda.', 'Qinisekisa ukukhetha i-fungicide ngeseluleko sendawo.', 'Sinizya kusalwa kwafungicide amalayilile acabalo.'),
    ],
    prevention: [
      LT('Rotate away from potato and tomato crops.', 'Chinjanisa kubva pambatatisi nemadomasi.', 'Tshintshanisa ungasimi amazambane kumbe utamatisi endaweni efanayo njalo.', 'Cinjanya kutali ambatatisi atomato.'),
      LT('Use clean seed potatoes.', 'Shandisa seed potatoes dzakachena.', 'Sebenzisa amazambane embewu ahlanzekileyo.', 'Belensya seed potato zicena.'),
      LT('Manage crop debris after harvest.', 'Chenesa masara ezvirimwa mushure mekukohwa.', 'Phatha insalela ngemva kokuvuna.', 'Longa masala mwamana kuuna.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Potato',
    name: LT('Late Blight', 'Late Blight', 'Late Blight', 'Late Blight'),
    shortSymptom: LT('Dark rapidly enlarging lesions during cool humid weather.', 'Mavanga dark anokura nekukurumidza kana kuchitonhora uye humidity yakakwira.', 'Amabala amnyama akhula masinya lapho kupholile ku-humid.', 'Mabala mnyama alakula cakufwamba naa kwatontola ahumidity yapati.'),
    symptoms: [
      LT('Dark irregular leaf lesions.', 'Mavanga dark asina shape yakafanana pamashizha.', 'Amabala amnyama angalinganiyo emaqabungeni.', 'Mabala mnyama atalingani amashizha.'),
      LT('White growth can appear at lesion edges underneath leaves.', 'White growth inogona kuoneka kumicheto yemavanga pasi pemashizha.', 'Ukukhula okumhlophe kungavela emaphethelweni ngaphansi kwamaqabunga.', 'Bintu zicituba zilakuboneka mumbali yamabala ansi amashizha.'),
      LT('Stems and tubers may also become infected.', 'Madzinde nematuber zvinogonawo kubatwa.', 'Iziqu lezilimo ezingaphansi komhlabathi zingatheleleka.', 'Misinde atubers zilakujatwa.'),
    ],
    spread: [
      LT('Cool humid weather, rain and wind-blown spores.', 'Kutonhora, humidity, mvura nemhepo inofambisa spores.', 'Isimo esipholileyo esile-humidity, imvula lama-spore ahanjiswa ngumoya.', 'Mvula itontola iile humidity, mvula ama-spore afambiswa lyuwo.'),
      LT('Infected tubers and volunteer plants can be sources.', 'Matuber ane chirwere nezvirimwa zvinomera zvega zvinogona kuva source.', 'Ama-tuber athelelekileyo lezitshalo ezimila zodwa zingaba ngumthombo.', 'Tubers zajatwa amilimo imela yoonse zilaba siko lyabulwazi.'),
    ],
    actions: [
      LT('Act quickly when symptoms are suspected.', 'Ita nekukurumidza kana uchifungidzira zviratidzo.', 'Thatha inyathelo masinya nxa usola izimpawu.', 'Cita cakufwamba naa wabona zibonakaliso.'),
      LT('Keep infected foliage away from healthy crops.', 'Bvisa mashizha ane chirwere kure nezvirimwa zvine hutano.', 'Gcina amaqabunga athelelekileyo kude lezilimo eziphilileyo.', 'Bweza mashizha ajatwa kutali amilimo ipona.'),
      LT('Contact an extension officer for local control advice.', 'Bata extension officer kuti uwane mazano emunharaunda.', 'Xhumana lesiphathamandla se-extension ngeseluleko sendawo.', 'Buzya mugwasyi wabalimi amalayilile acabalo.'),
    ],
    prevention: [
      LT('Use certified clean seed.', 'Shandisa mbeu yakasimbiswa uye yakachena.', 'Sebenzisa imbewu eqinisekisiweyo ehlanzekileyo.', 'Belensya mbeu yasinizidwe iicena.'),
      LT('Destroy volunteer potatoes.', 'Bvisa mbatatisi dzinomera zvega.', 'Bulala amazambane azimilelayo.', 'Bweza potato zimela zyoonse.'),
      LT('Monitor closely during wet cool periods.', 'Tarisa zvakanyanya kana kuchitonhora uye kwakanyorova.', 'Hlola kakhulu ngesikhathi esimanzi esipholileyo.', 'Langa kapati naa kwatontola akunyowa.'),
    ],
  ),
  DiseaseInfo(
    crop: 'Bell pepper',
    name: LT('Bacterial Spot', 'Bacterial Spot', 'Bacterial Spot', 'Bacterial Spot'),
    shortSymptom: LT('Small dark water-soaked spots that can become brown and angular.', 'Mavanga madiki dark akaita semvura anogona kuva brown uye angular.', 'Amabala amancane amnyama abonakala emanzi angaba nsundu njalo abe angular.', 'Mabala masyoonto mnyama masiita amanzi alaba brown aa angular.'),
    symptoms: [
      LT('Small dark spots on leaves.', 'Mavanga madiki dark pamashizha.', 'Amabala amancane amnyama emaqabungeni.', 'Mabala masyoonto mnyama amashizha.'),
      LT('Spots may become angular and leaves can yellow.', 'Mavanga anogona kuva angular uye mashizha anoita yellow.', 'Amabala angaba angular njalo amaqabunga abe yellow.', 'Mabala alaba angular amashizha aba yellow.'),
      LT('Fruit can develop raised rough lesions.', 'Michero inogona kuva nemavanga akasimuka uye akaomarara.', 'Izithelo zingaba lamabala aphakemeyo alukhuni.', 'Micelo ilaba mabala aasimuka aalukukutu.'),
    ],
    spread: [
      LT('Splashing rain, overhead irrigation and contaminated seed or tools.', 'Mvura inosasa, kudiridza pamusoro uye mbeu kana maturusi ane bacteria.', 'Ukutshaya kwemvula, ukunisela phezu kwamahlamvu lembewu kumbe amathuluzi angcolileyo.', 'Kupazika kwamvula, kudilila ansengwe amashizha ambeu naa zyakubelensya zyamanyina.'),
      LT('Warm wet weather increases spread.', 'Kupisa uye kunyorova kunowedzera kupararira.', 'Isimo esifudumele esimanzi sandisa ukusabalala.', 'Mvula iipya imanzi ilasumpula kuzwidila.'),
    ],
    actions: [
      LT('Remove badly infected leaves and fruit.', 'Bvisa mashizha nemichero zvakabatwa zvakanyanya.', 'Susa amaqabunga lezithelo ezitheleke kakhulu.', 'Bweza mashizha amicelo yajata kapati.'),
      LT('Avoid working plants while wet.', 'Usashanda zvirimwa kana zvakanyorova.', 'Gwema ukusebenza izitshalo zisemanzi.', 'Tandika kubamba milimo naa imanzi.'),
      LT('Disinfect tools between affected areas.', 'Disinfect maturusi pakati penzvimbo dzakabatwa.', 'Bulala amagciwane emathuluzini phakathi kwezindawo ezithintekileyo.', 'Cenesa zyakubelensya pakati kabusena bwajatwa.'),
    ],
    prevention: [
      LT('Start with clean seed or seedlings.', 'Tanga nembeu kana seedlings dzakachena.', 'Qala ngembewu kumbe izithombo ezihlanzekileyo.', 'Tanga ambeu naa seedlings zicena.'),
      LT('Rotate crops.', 'Chinjanisa zvirimwa.', 'Tshintshanisa izilimo.', 'Cinjanya milimo.'),
      LT('Avoid overhead watering when possible.', 'Usadiridzire pamusoro pemashizha kana zvichikwanisika.', 'Gwema ukunisela phezu kwamahlamvu nxa kungenzeka.', 'Tandika kudilila ansengwe mashizha naa kulakonzya.'),
    ],
  ),
];
