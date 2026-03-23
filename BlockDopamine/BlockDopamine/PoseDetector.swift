import Foundation
import ARKit
import Combine

class PoseDetector: NSObject, ObservableObject, ARSessionDelegate {
    @Published var flexionesContadas = 0
    private var estaAbajo = false
    private var ultimaFlexion = Date()
    
    let arSession = ARSession()

    func empezar() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("SISTEMA: Error. Este iPhone no tiene cámara TrueDepth frontal.")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        arSession.delegate = self
        arSession.run(configuration)
        print("SISTEMA: Sensores infrarrojos 3D encendidos")
    }
    
    func resetearContador() {
        DispatchQueue.main.async {
            self.flexionesContadas = 0
            self.estaAbajo = false
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Obtenemos tu cara Y LA CÁMARA
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first,
              let camera = session.currentFrame?.camera else {
            return
        }

        // 1. Posición de la cámara en el espacio 3D
        let cx = camera.transform.columns.3.x
        let cy = camera.transform.columns.3.y
        let cz = camera.transform.columns.3.z
        
        // 2. Posición de tu cara en el espacio 3D
        let fx = faceAnchor.transform.columns.3.x
        let fy = faceAnchor.transform.columns.3.y
        let fz = faceAnchor.transform.columns.3.z
        
        // ⭐️ 3. LA MAGIA: Teorema de Pitágoras 3D para la distancia real absoluta
        let distanciaMetros = sqrt(pow(cx - fx, 2) + pow(cy - fy, 2) + pow(cz - fz, 2))
        
        print("DEBUG: Distancia 3D = \(String(format: "%.3f", distanciaMetros)) metros")

        DispatchQueue.main.async {
            // He puesto límites genéricos (15cm y 35cm). ¡Mira tu consola para ajustarlos si hace falta!
            
            // ABAJO: Te acercas al móvil
            if distanciaMetros <= 0.3 && !self.estaAbajo {
                self.estaAbajo = true
                print("SISTEMA: >>> ABAJO")
            }
            
            // ARRIBA: Te alejas del móvil
            else if distanciaMetros >= 0.45 && self.estaAbajo {
                let tiempoDesdeUltima = Date().timeIntervalSince(self.ultimaFlexion)
                
                if tiempoDesdeUltima > 0.4 {
                    self.flexionesContadas += 1
                    self.ultimaFlexion = Date()
                    self.estaAbajo = false
                    print("SISTEMA: >>> ¡FLEXIÓN #\(self.flexionesContadas)!")
                } else {
                    self.estaAbajo = false
                }
            }
        }
    }
    // Añade esto dentro de tu clase PoseDetector
    func guardarMinutos(_ minutos: Int) {
        UserDefaults.standard.set(minutos, forKey: "minutos_disponibles")
    }

    func cargarMinutos() -> Int {
        return UserDefaults.standard.integer(forKey: "minutos_disponibles")
    }
}
