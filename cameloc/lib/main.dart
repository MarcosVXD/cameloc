
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

const papel = Color(0xFFF5E8C7);
const preto = Color(0xFF171717);
const vermelho = Color(0xFFD92D32);
const azul = Color(0xFF1769AA);
const amarelo = Color(0xFFFFD447);
const branco = Color(0xFFFFFCF1);

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Super Perfil',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: papel,
          colorScheme: ColorScheme.fromSeed(seedColor: vermelho),
        ),
        home: const TelaPerfil(),
      );
}

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final nome = TextEditingController();
  final picker = ImagePicker();

  Uint8List? foto;
  CameraController? camera;
  String localizacao = 'Localização ainda não obtida';

  bool localizacaoObtida = false;
  bool buscandoLocalizacao = false;
  bool abrindoCamera = false;

  Future<void> abrirCamera() async {
    setState(() => abrindoCamera = true);
    CameraController? novaCamera;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Nenhuma câmera encontrada.');

      final escolhida = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      novaCamera = CameraController(
        escolhida,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await novaCamera.initialize();

      if (!mounted) {
        await novaCamera.dispose();
        return;
      }

      setState(() {
        camera = novaCamera;
        abrindoCamera = false;
      });
    } catch (e) {
      await novaCamera?.dispose();
      if (!mounted) return;

      setState(() => abrindoCamera = false);
      mensagem('Não foi possível abrir a câmera: $e');
    }
  }

  Future<void> tirarFoto() async {
    if (camera == null || !camera!.value.isInitialized) return;

    try {
      final imagem = await camera!.takePicture();
      final bytes = await imagem.readAsBytes();

      if (!mounted) return;
      setState(() => foto = bytes);
      await fecharCamera();
    } catch (e) {
      mensagem('Erro ao tirar foto: $e');
    }
  }

  Future<void> escolherGaleria() async {
    try {
      final imagem = await picker.pickImage(source: ImageSource.gallery);
      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();
      if (mounted) setState(() => foto = bytes);
    } catch (e) {
      mensagem('Erro ao abrir a galeria: $e');
    }
  }

  Future<void> fecharCamera() async {
    final antiga = camera;
    camera = null;
    if (mounted) setState(() {});
    await antiga?.dispose();
  }

  Future<void> obterLocalizacao() async {
    setState(() => buscandoLocalizacao = true);

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Ative o serviço de localização.');
      }

      var permissao = await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada.');
      }

      final posicao = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        localizacao =
            'LAT: ${posicao.latitude.toStringAsFixed(4)}\n'
            'LON: ${posicao.longitude.toStringAsFixed(4)}';
        localizacaoObtida = true;
        buscandoLocalizacao = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        localizacao = e.toString().replaceFirst('Exception: ', '');
        localizacaoObtida = false;
        buscandoLocalizacao = false;
      });
    }
  }

  void mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Widget quadro(
    Widget child, {
    Color cor = branco,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cor,
        border: Border.all(color: preto, width: 3),
        boxShadow: const [
          BoxShadow(color: preto, offset: Offset(4, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget faixa(String texto, {Color cor = preto, Color tinta = branco}) {
    return Container(
      width: double.infinity,
      color: cor,
      padding: const EdgeInsets.all(11),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: tinta,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget botao(
    String texto,
    IconData icone,
    VoidCallback? acao, {
    Color cor = branco,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: acao,
        icon: Icon(icone),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: preto,
          elevation: 0,
          padding: const EdgeInsets.all(16),
          side: const BorderSide(color: preto, width: 3),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget secao(String numero, String titulo, Color cor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          color: amarelo,
          child: Text(
            numero,
            style: const TextStyle(
              color: preto,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(child: faixa(titulo, cor: cor)),
      ],
    );
  }

  Widget explosao(String texto, {Color cor = amarelo}) {
    return SizedBox(
      width: 82,
      height: 72,
      child: CustomPaint(
        painter: ExplosaoPainter(cor),
        child: Center(
          child: Text(
            texto,
            style: const TextStyle(
              color: preto,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nome.dispose();
    camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ativa = camera != null && camera!.value.isInitialized;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: vermelho,
        foregroundColor: branco,
        centerTitle: true,
        title: const Text(
          'HQ  SUPER PERFIL!',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(height: 4, color: preto),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: ReticulaPainter())),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 25, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: quadro(
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ARQUIVO CONFIDENCIAL',
                                  style: TextStyle(
                                    color: amarelo,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'QUEM É VOCÊ?',
                                  style: TextStyle(
                                    color: branco,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            cor: preto,
                          ),
                        ),
                        const SizedBox(width: 12),
                        explosao('POW!'),
                      ],
                    ),

                    const SizedBox(height: 26),

                    quadro(
                      Column(
                        children: [
                          faixa(
                            'IDENTIDADE SECRETA • Nº 001',
                            tinta: amarelo,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: vermelho,
                              shape: BoxShape.circle,
                              border: Border.all(color: preto, width: 4),
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: azul,
                              backgroundImage:
                                  foto == null ? null : MemoryImage(foto!),
                              child: foto == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 75,
                                      color: branco,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'NOME DO PERSONAGEM:',
                              style: TextStyle(
                                color: preto,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nome,
                            decoration: const InputDecoration(
                              hintText: 'Digite seu nome...',
                              filled: true,
                              fillColor: branco,
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: preto,
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(
                                  color: preto,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'TODO HERÓI TEM UMA IDENTIDADE. ESTA É A SUA!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: preto,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      cor: amarelo,
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 34),
                    secao('01', 'CAPTURE SEU RETRATO', vermelho),
                    const SizedBox(height: 18),

                    if (ativa) ...[
                      quadro(
                        Column(
                          children: [
                            faixa('CÂMERA AO VIVO', cor: azul),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: camera!.value.aspectRatio,
                              child: CameraPreview(camera!),
                            ),
                          ],
                        ),
                        cor: preto,
                        padding: const EdgeInsets.all(7),
                      ),
                      const SizedBox(height: 14),
                      botao('CLIC! CAPTURAR FOTO', Icons.camera_alt, tirarFoto,
                          cor: amarelo),
                      const SizedBox(height: 10),
                      botao('FECHAR CÂMERA', Icons.close, fecharCamera),
                    ] else ...[
                      quadro(
                        const Column(
                          children: [
                            Icon(Icons.camera_alt, size: 42, color: preto),
                            SizedBox(height: 8),
                            Text(
                              'O PRÓXIMO QUADRO É SEU!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: preto,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Prepare-se para a ação.',
                              style: TextStyle(
                                color: preto,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        cor: const Color(0xFFB8DDF1),
                      ),
                      const SizedBox(height: 16),
                      botao(
                        abrindoCamera ? 'ABRINDO CÂMERA...' : 'ABRIR CÂMERA',
                        Icons.camera_alt,
                        abrindoCamera ? null : abrirCamera,
                        cor: amarelo,
                      ),
                    ],

                    const SizedBox(height: 10),
                    botao(
                      'ESCOLHER DA GALERIA',
                      Icons.photo_library,
                      escolherGaleria,
                    ),

                    const SizedBox(height: 34),
                    secao('02', 'RASTREADOR DE HERÓIS', azul),
                    const SizedBox(height: 18),

                    quadro(
                      Column(
                        children: [
                          faixa(
                            'CENTRAL DE LOCALIZAÇÃO',
                            tinta: amarelo,
                          ),
                          const SizedBox(height: 18),
                          Icon(
                            localizacaoObtida
                                ? Icons.location_on
                                : Icons.location_searching,
                            color: localizacaoObtida ? Colors.green : vermelho,
                            size: 54,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            localizacaoObtida
                                ? 'ALVO LOCALIZADO!'
                                : 'SINAL AGUARDANDO...',
                            style: const TextStyle(
                              color: preto,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: branco,
                              border: Border.all(color: preto, width: 3),
                            ),
                            child: Text(
                              localizacao,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: preto,
                                fontWeight: FontWeight.w900,
                                height: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      cor: const Color(0xFFB8DDF1),
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 18),
                    botao(
                      buscandoLocalizacao
                          ? 'RASTREANDO POSIÇÃO...'
                          : 'DESCOBRIR MINHA LOCALIZAÇÃO',
                      Icons.my_location,
                      buscandoLocalizacao ? null : obterLocalizacao,
                      cor: amarelo,
                    ),

                    const SizedBox(height: 34),
                    quadro(
                      const Column(
                        children: [
                          Text(
                            'FIM?',
                            style: TextStyle(
                              color: amarelo,
                              fontSize: 38,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Divider(color: preto, thickness: 3),
                          Text(
                            'CONTINUA NA PRÓXIMA EDIÇÃO...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: branco,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      cor: vermelho,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'UMA IDENTIDADE. UMA HISTÓRIA. UM HERÓI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: preto,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExplosaoPainter extends CustomPainter {
  final Color cor;

  ExplosaoPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const pontos = 14;

    for (int i = 0; i < pontos * 2; i++) {
      final angulo = -math.pi / 2 + i * math.pi / pontos;
      final raio = i.isEven ? 1.0 : 0.67;
      final x = size.width / 2 + math.cos(angulo) * size.width / 2 * raio;
      final y = size.height / 2 + math.sin(angulo) * size.height / 2 * raio;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.save();
    canvas.translate(4, 4);
    canvas.drawPath(path, Paint()..color = preto);
    canvas.restore();

    canvas.drawPath(path, Paint()..color = cor);
    canvas.drawPath(
      path,
      Paint()
        ..color = preto
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant ExplosaoPainter oldDelegate) =>
      cor != oldDelegate.cor;
}

class ReticulaPainter extends CustomPainter {
  const ReticulaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(papel, BlendMode.src);

    final azulTinta = Paint()..color = azul.withOpacity(0.17);
    final vermelhaTinta = Paint()..color = vermelho.withOpacity(0.13);

    for (double y = 0; y < size.height; y += 14) {
      for (double x = 0; x < size.width; x += 14) {
        final dxTopo = (x - size.width * 0.95) / (size.width * 0.35);
        final dyTopo = (y - size.height * 0.03) / (size.height * 0.20);
        final dxBaixo = (x - size.width * 0.03) / (size.width * 0.27);
        final dyBaixo = (y - size.height * 0.97) / (size.height * 0.17);

        if (dxTopo * dxTopo + dyTopo * dyTopo < 1) {
          canvas.drawCircle(Offset(x, y), 1.7, azulTinta);
        }

        if (dxBaixo * dxBaixo + dyBaixo * dyBaixo < 1) {
          canvas.drawCircle(Offset(x, y), 1.7, vermelhaTinta);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ReticulaPainter oldDelegate) => false;
}
