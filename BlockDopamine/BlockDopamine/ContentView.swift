import SwiftUI
import ARKit
import Combine
import UserNotifications

// 1. VISOR 3D (Se mantiene igual)
struct VisorARKit: UIViewRepresentable {
    var session: ARSession
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = session
        return arView
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

struct Tanda: Identifiable, Codable {
    var id = UUID()
    let fecha: Date
    let flexiones: Int
    let minutosGanados: Int
}

struct ContentView: View {
    @StateObject private var poseDetector = PoseDetector()
    
    // --- ESTADOS PERSISTENTES ---
    @AppStorage("segundosDisponibles") private var segundosDisponibles: Int = 0
    @AppStorage("multiplicador") private var multiplicador: Int = 1
    @AppStorage("appsBloqueadas") private var appsParaVigilar: String = ""
    
    @State private var isEntrenando = false
    @State private var historial: [Tanda] = []
    @State private var timerActivo = false
    
    var body: some View {
        ZStack {
            if isEntrenando {
                vistaEntrenamiento
            } else {
                vistaMenuPrincipal
            }
        }
        // Detecta el regreso de TikTok
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("SISTEMA: App regresando...")
            // ORDEN IMPORTANTE: Primero calculamos, luego actualizamos permiso
            recalcularTiempoConsumido()
            actualizarPermisoSistema()
        }
        .onOpenURL { url in
            if url.absoluteString.contains("iniciar") {
                if segundosDisponibles > 0 {
                    timerActivo = true
                    // Programamos notificación basada en segundos actuales
                    programarNotificacion(segundos: segundosDisponibles)
                }
            }
        }
        // IMPORTANTE: Ahora vigilamos segundosDisponibles
        .onChange(of: segundosDisponibles) { _ in actualizarPermisoSistema() }
        .onAppear {
            actualizarPermisoSistema()
            recalcularTiempoConsumido()
        }
    }

    // MARK: - VISTAS
    
    private var vistaMenuPrincipal: some View {
        VStack(spacing: 25) {
            Text("Dopamina").font(.largeTitle).fontWeight(.black).padding(.top)
            
            VStack {
                Text("TIEMPO DISPONIBLE").font(.caption).foregroundColor(.gray)
                
                // Reloj en formato 00:00
                Text(tiempoFormateado(segundosDisponibles))
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(segundosDisponibles > 0 ? .blue : .red)
                
                if timerActivo {
                    Text("⏳ TikTok activo...").foregroundColor(.orange).bold().font(.caption)
                }
            }
            .padding().frame(maxWidth: .infinity).background(Color.blue.opacity(0.1)).cornerRadius(20).padding()

            VStack(spacing: 15) {
                TextField("App (ej: TikTok)", text: $appsParaVigilar).textFieldStyle(RoundedBorderTextFieldStyle())
                Picker("Recompensa", selection: $multiplicador) {
                    ForEach(1...5, id: \.self) { Text("x\($0) min").tag($0) }
                }.pickerStyle(SegmentedPickerStyle())
            }.padding(.horizontal)

            Button(action: { isEntrenando = true }) {
                Text("GANAR MINUTOS").font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding().background(Color.green).cornerRadius(15)
            }.padding(.horizontal)

            List(historial) { t in
                HStack {
                    Text(t.fecha, style: .time).foregroundColor(.gray)
                    Spacer()
                    Text("\(t.flexiones) flx")
                    Text("+\(t.minutosGanados) min").foregroundColor(.green).bold()
                }
            }.listStyle(PlainListStyle())
        }
    }

    private var vistaEntrenamiento: some View {
        ZStack {
            VisorARKit(session: poseDetector.arSession).edgesIgnoringSafeArea(.all)
            VStack {
                Text("\(poseDetector.flexionesContadas)").font(.system(size: 80, weight: .heavy))
                    .foregroundColor(.white).padding().background(Color.black.opacity(0.5)).clipShape(Circle())
                Spacer()
                Button("TERMINAR") {
                    cobrarTanda()
                }.font(.headline).padding().frame(maxWidth: .infinity).background(Color.red).foregroundColor(.white).cornerRadius(15).padding()
            }
        }.onAppear { poseDetector.empezar() }.onDisappear { poseDetector.arSession.pause() }
    }

    // MARK: - LÓGICA
    
    private func cobrarTanda() {
        if poseDetector.flexionesContadas > 0 {
            let minutosGanados = poseDetector.flexionesContadas * multiplicador
            segundosDisponibles += (minutosGanados * 60)
            historial.insert(Tanda(fecha: Date(), flexiones: poseDetector.flexionesContadas, minutosGanados: minutosGanados), at: 0)
            
            // ¡ESTO ES CLAVE! Actualiza el portapapeles a "SI" al instante
            actualizarPermisoSistema()
        }
        isEntrenando = false
    }

    private func recalcularTiempoConsumido() {
        guard let contenido = UIPasteboard.general.string else {
            print("SISTEMA: Portapapeles vacío")
            return
        }
        
        print("SISTEMA: Contenido detectado: \(contenido)")
        
        // Si el portapapeles tiene el permiso, no hay fecha que calcular
        if contenido == "SI" || contenido == "NO" {
            print("SISTEMA: No hay fecha, solo estado \(contenido)")
            return
        }

        let isoFormatter = ISO8601DateFormatter()
        if let fechaInicio = isoFormatter.date(from: contenido) {
            let diferencia = Int(Date().timeIntervalSince(fechaInicio))
            
            if diferencia > 0 {
                segundosDisponibles = max(0, segundosDisponibles - diferencia)
                print("⚠️ RESTA OK: -\(diferencia) segundos. Nuevo saldo: \(segundosDisponibles)")
            }
            timerActivo = false
        } else {
            print("❌ ERROR: El texto '\(contenido)' no tiene formato ISO8601")
        }
    }

    private func tiempoFormateado(_ segundos: Int) -> String {
        let m = segundos / 60
        let s = segundos % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func actualizarPermisoSistema() {
        // Usamos segundosDisponibles para decidir el permiso
        let estado = segundosDisponibles > 0 ? "SI" : "NO"
        UIPasteboard.general.string = estado
        print("SISTEMA: Permiso actualizado a \(estado)")
    }

    private func programarNotificacion(segundos: Int) {
        let contenido = UNMutableNotificationContent()
        contenido.title = "⚠️ ¡TIEMPO AGOTADO!"
        contenido.body = "Se acabó tu tiempo. ¡A por más flexiones!"
        contenido.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(segundos), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "AVISO_DOPAMINA", content: contenido, trigger: trigger))
    }
}
