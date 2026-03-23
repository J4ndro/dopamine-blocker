# 🧠 DopamineLock: Fitness-Gated Social Media

<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 Pro - 2026-03-23 at 20 40 23" src="https://github.com/user-attachments/assets/68ed6edd-bdda-458c-906e-720e0dc6b6ef" />

**DopamineLock** es una aplicación de productividad para iOS diseñada para combatir la adicción a las redes sociales (especialmente TikTok/Instagram) mediante el refuerzo positivo y el ejercicio físico. 

La premisa es simple: **Si quieres "dopamina digital", primero tienes que ganártela con esfuerzo físico.**

---

## 🚀 ¿Cómo funciona?

1.  **Entrenamiento AR:** La app utiliza **ARKit** y **Body Tracking** para contar tus flexiones en tiempo real usando la cámara frontal.
2.  **Conversión de Esfuerzo:** Cada flexión realizada se convierte en tiempo de uso (segundos/minutos) para tus apps vigiladas.
3.  **Bloqueo Inteligente:** Mediante **Atajos de iOS (Shortcuts)** y el **Portapapeles**, la app detecta si tienes "saldo" antes de permitirte abrir una red social. 
4.  **Descuento Automático:** Al cerrar la red social, la app calcula exactamente cuántos segundos estuviste dentro y los resta de tu saldo disponible.

---

## 🛠️ Stack Tecnológico

* **SwiftUI:** Para una interfaz moderna y reactiva.
* **ARKit:** Seguimiento de esqueleto humano para detección de poses.
* **Combine:** Gestión de eventos y actualizaciones de sensores.
* **AppStorage:** Persistencia de datos local.
* **iOS Shortcuts Integration:** El "puente" para controlar otras aplicaciones del sistema.

---

## 📖 Guía de Configuración (Imprescindible)

Para que el sistema de bloqueo funcione, debes configurar dos Automatizaciones en la app **Atajos** de tu iPhone:

### 1. Automatización: Al abrir [App Social]
* **Activador:** Al abrir TikTok (o la app que elijas).
* **Lógica:**
    * `Obtener portapapeles`
    * `Si [Portapapeles] es SI`:
        * `Obtener Fecha actual` -> `Formatear Fecha (ISO 8601)`
        * `Copiar [Fecha formateada] al portapapeles`
    * `Si no`:
        * `Abrir App [DopamineLock]`
* **Configuración:** Desactivar "Preguntar al ejecutar" y activar "Ejecutar inmediatamente".

### 2. Automatización: Al cerrar [App Social]
* **Activador:** Al cerrar TikTok.
* **Acción:** `Abrir App [DopamineLock]`.
* **Propósito:** Esto permite que la app se despierte, lea el tiempo de inicio del portapapeles y descuente los segundos consumidos.

---

## 📋 Requisitos de Instalación

1.  Clonar el repositorio.
2.  Abrir en **Xcode 15+**.
3.  Conectar un iPhone físico (ARKit no funciona en el simulador).
4.  En **Ajustes > [Tu App] > Pegar desde otras apps**, seleccionar **Permitir** (para evitar el aviso de privacidad constante).

---

## 🤝 Contribuciones

Las sugerencias son bienvenidas. Actualmente, el sistema de detección se centra en flexiones, pero el modelo es escalable a sentadillas o saltos.

---

**Desarrollado con ⚡️ y mucho Swift.**
