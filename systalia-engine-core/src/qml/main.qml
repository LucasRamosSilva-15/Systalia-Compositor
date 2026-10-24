import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Systalia.Engine 1.0

ApplicationWindow {
    id: rootWindow
    width: 1440
    height: 900
    minimumWidth: 1024
    minimumHeight: 720
    visible: true
    title: qsTr("Systalia Glass Engine (SGE) — VALO Optical SDF Harness [Vulkan RHI]")
    color: "#050b14"

    // =========================================================================
    // 1. CENA DE FUNDO DINÂMICA DE ELEVADO CONTRASTE (Para teste de refração)
    // =========================================================================
    Item {
        id: backgroundScene
        anchors.fill: parent

        // 1.1 Fundo base abissal com gradiente
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#040810" }
                GradientStop { position: 0.5; color: "#081324" }
                GradientStop { position: 1.0; color: "#03060c" }
            }
        }

        // 1.2 Grelha analítica de teste de alta frequência (linhas finas de 1px)
        Canvas {
            id: gridCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.strokeStyle = "rgba(0, 229, 255, 0.08)";
                ctx.lineWidth = 1;
                for (var x = 0; x < width; x += 32) {
                    ctx.beginPath();
                    ctx.moveTo(x + 0.5, 0);
                    ctx.lineTo(x + 0.5, height);
                    ctx.stroke();
                }
                for (var y = 0; y < height; y += 32) {
                    ctx.beginPath();
                    ctx.moveTo(0, y + 0.5);
                    ctx.lineTo(width, y + 0.5);
                    ctx.stroke();
                }

                // Linhas mestras a cada 160px
                ctx.strokeStyle = "rgba(0, 255, 163, 0.18)";
                ctx.lineWidth = 1.5;
                for (var mx = 0; mx < width; mx += 160) {
                    ctx.beginPath();
                    ctx.moveTo(mx + 0.5, 0);
                    ctx.lineTo(mx + 0.5, height);
                    ctx.stroke();
                }
                for (var my = 0; my < height; my += 160) {
                    ctx.beginPath();
                    ctx.moveTo(0, my + 0.5);
                    ctx.lineTo(width, my + 0.5);
                    ctx.stroke();
                }
            }
        }

        // 1.3 Elementos Geométricos Animados de Elevado Contraste
        Item {
            id: animatedElements
            anchors.fill: parent

            // Disco grande rotativo magenta/ciano
            Rectangle {
                id: orbMagenta
                width: 380
                height: 380
                radius: 190
                x: 180 + Math.sin(animTimer.angle * 0.7) * 120
                y: 120 + Math.cos(animTimer.angle * 0.5) * 80
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#ff007a" }
                    GradientStop { position: 0.5; color: "#7928ca" }
                    GradientStop { position: 1.0; color: "#00e5ff" }
                }
                opacity: 0.85
            }

            // Disco turquesa orgânico
            Rectangle {
                id: orbCyan
                width: 320
                height: 320
                radius: 160
                x: parent.width - 500 + Math.cos(animTimer.angle * 0.8) * 140
                y: 260 + Math.sin(animTimer.angle * 0.6) * 110
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#00ffa3" }
                    GradientStop { position: 0.7; color: "#00b4d8" }
                    GradientStop { position: 1.0; color: "#0077b6" }
                }
                opacity: 0.8
            }

            // Anel geométrico dourado/laranja
            Rectangle {
                width: 260
                height: 260
                radius: 130
                color: "transparent"
                border.color: "#ffbe0b"
                border.width: 14
                x: 480 + Math.sin(animTimer.angle * 1.1) * 160
                y: 380 + Math.cos(animTimer.angle * 0.9) * 90
                opacity: 0.9
            }

            // Padrão xadrez de alta frequência para teste de refração
            Grid {
                x: 350
                y: 180
                rows: 6
                columns: 10
                spacing: 4
                Repeater {
                    model: 60
                    Rectangle {
                        width: 24
                        height: 24
                        color: (index % 2 === 0) ? "#00e5ff" : "#ff0055"
                        opacity: 0.75
                    }
                }
            }

            // Ticker de texto em movimento
            Row {
                id: marqueeRow
                x: -100 + (animTimer.tick * 80) % (rootWindow.width + 800) - 400
                y: rootWindow.height - 80
                spacing: 40

                Repeater {
                    model: 4
                    Text {
                        text: "SYSTALIA VALO GLASS OPTICAL ENGINE • CAUCHY DISPERSION • G2 SQUIRCLE SDF • VULKAN RHI • ZERO BLUR BLEED"
                        color: "#00e5ff"
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetBrains Mono, monospace"
                        opacity: 0.6
                    }
                }
            }
        }
    }

    // Timer para animação contínua (60 FPS)
    Timer {
        id: animTimer
        interval: 16
        running: true
        repeat: true
        property real tick: 0.0
        property real angle: 0.0
        onTriggered: {
            tick += 0.016;
            angle += 0.02;
        }
    }

    // =========================================================================
    // 2. CAPTURA ATIVA DO BACKDROP FRAMEBUFFER (Com dimensões explícitas para Vulkan FBO)
    // =========================================================================
    ShaderEffectSource {
        id: backdropGrab
        anchors.fill: backgroundScene
        sourceItem: backgroundScene
        textureSize: Qt.size(Math.max(1, rootWindow.width * rootWindow.devicePixelRatio),
                             Math.max(1, rootWindow.height * rootWindow.devicePixelRatio))
        live: true
        hideSource: false
        recursive: false
        format: ShaderEffectSource.RGBA8
    }

    // =========================================================================
    // 3. CHASSIS UNIFICADO DE CRISTAL LÍQUIDO VALO GLASS
    // O próprio SystaliaGlassItem é o container centralizado da janela (uma única placa)
    // =========================================================================
    SystaliaGlassItem {
        id: glassChassis
        width: 860
        height: 580
        anchors.centerIn: parent

        backdropSource: backdropGrab
        screenResolution: Qt.vector2d(rootWindow.width * rootWindow.devicePixelRatio,
                                      rootWindow.height * rootWindow.devicePixelRatio)

        // Sincronização dos parâmetros ópticos e de geometria G2
        radii: Qt.vector4d(sliderRTL.value, sliderRTR.value, sliderRBL.value, sliderRBR.value)
        slant: sliderSlant.value
        ior: sliderIOR.value
        chromaticDispersion: sliderDispersion.value
        causticIntensity: sliderCaustic.value
        surfaceOpacity: sliderOpacity.value

        // Arraste livre da janela pelo utilizador
        DragHandler {
            id: windowDrag
            target: glassChassis
        }

        // =====================================================================
        // 4. CAMADA DE CONTEÚDO INTEGRADA E 100% TRANSPARENTE
        // (Sem sub-retângulos escuros: todo o conteúdo repousa sobre a mesma placa de vidro)
        // =====================================================================
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            // 4.1 Barra de Título Unificada
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 12

                // Ícone Óptico Systalia
                Rectangle {
                    width: 26
                    height: 26
                    radius: 7
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00e5ff" }
                        GradientStop { position: 1.0; color: "#00ffa3" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "S"
                        color: "#050b14"
                        font.bold: true
                        font.pixelSize: 13
                    }
                }

                // Títulos do Chassi
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "SYSTALIA GLASS ENGINE — VALO OPTICAL SDF"
                        color: "#f8fafc"
                        font.bold: true
                        font.pixelSize: 12
                        font.family: "Segoe UI, Inter, sans-serif"
                    }
                    Text {
                        text: "Placa Única de Cristal Óptico G2 • Vulkan RHI Native • Screen-Space UV"
                        color: "#00e5ff"
                        font.pixelSize: 10
                        font.family: "JetBrains Mono, monospace"
                    }
                }

                Item { Layout.fillWidth: true }

                // Badges de Telemetria
                Rectangle {
                    height: 20
                    width: 82
                    radius: 4
                    color: "#2000e5ff"
                    border.color: "#5000e5ff"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "VK RHI NATIVE"
                        color: "#00e5ff"
                        font.pixelSize: 9
                        font.bold: true
                        font.family: "JetBrains Mono, monospace"
                    }
                }

                Rectangle {
                    height: 20
                    width: 60
                    radius: 4
                    color: "#2000ffa3"
                    border.color: "#5000ffa3"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "SDF G2"
                        color: "#00ffa3"
                        font.pixelSize: 9
                        font.bold: true
                        font.family: "JetBrains Mono, monospace"
                    }
                }

                // Botões de Janela
                Row {
                    spacing: 8
                    Rectangle { width: 12; height: 12; radius: 6; color: "#22c55e"; border.color: "#40ffffff" }
                    Rectangle { width: 12; height: 12; radius: 6; color: "#eab308"; border.color: "#40ffffff" }
                    Rectangle { width: 12; height: 12; radius: 6; color: "#ef4444"; border.color: "#40ffffff" }
                }
            }

            // Separador de vidro ultra-sutil
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#18ffffff"
            }

            // 4.2 Deck Principal de Controlos (Layout Transparente em 2 Colunas)
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                // COLUNA 1: GEOMETRIA E CURVATURA SDF G2
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Text {
                        text: "◈ GEOMETRIA & CURVATURA SDF G2"
                        color: "#00e5ff"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "JetBrains Mono, monospace"
                    }

                    // Botões de Presets
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Button {
                            Layout.fillWidth: true
                            text: "Simétrico 24"
                            contentItem: Text {
                                text: parent.text
                                color: "#f8fafc"
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#4000e5ff" : "#1400e5ff"
                                radius: 5
                                border.color: "#4000e5ff"
                            }
                            onClicked: {
                                sliderRTL.value = 24;
                                sliderRTR.value = 24;
                                sliderRBL.value = 24;
                                sliderRBR.value = 24;
                                sliderSlant.value = 0.0;
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Domo 48"
                            contentItem: Text {
                                text: parent.text
                                color: "#f8fafc"
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#4000ffa3" : "#1400ffa3"
                                radius: 5
                                border.color: "#4000ffa3"
                            }
                            onClicked: {
                                sliderRTL.value = 48;
                                sliderRTR.value = 48;
                                sliderRBL.value = 12;
                                sliderRBR.value = 12;
                                sliderSlant.value = 0.35;
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Assimétrico"
                            contentItem: Text {
                                text: parent.text
                                color: "#f8fafc"
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignHCenter
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#40ff007a" : "#14ff007a"
                                radius: 5
                                border.color: "#40ff007a"
                            }
                            onClicked: {
                                sliderRTL.value = 42;
                                sliderRTR.value = 8;
                                sliderRBL.value = 8;
                                sliderRBR.value = 42;
                            }
                        }
                    }

                    // Slider Top-Left
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Raio Sup. Esq. (r_tl):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 140 }
                        Slider {
                            id: sliderRTL
                            Layout.fillWidth: true
                            from: 0.0
                            to: 64.0
                            value: 24.0
                        }
                        Text { text: Math.round(sliderRTL.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Top-Right
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Raio Sup. Dir. (r_tr):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 140 }
                        Slider {
                            id: sliderRTR
                            Layout.fillWidth: true
                            from: 0.0
                            to: 64.0
                            value: 24.0
                        }
                        Text { text: Math.round(sliderRTR.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Bottom-Left
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Raio Inf. Esq. (r_bl):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 140 }
                        Slider {
                            id: sliderRBL
                            Layout.fillWidth: true
                            from: 0.0
                            to: 64.0
                            value: 24.0
                        }
                        Text { text: Math.round(sliderRBL.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Bottom-Right
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Raio Inf. Dir. (r_br):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 140 }
                        Slider {
                            id: sliderRBR
                            Layout.fillWidth: true
                            from: 0.0
                            to: 64.0
                            value: 24.0
                        }
                        Text { text: Math.round(sliderRBR.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Slant
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Inclinação (Slant/Domo):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 140 }
                        Slider {
                            id: sliderSlant
                            Layout.fillWidth: true
                            from: -0.8
                            to: 0.8
                            value: 0.0
                        }
                        Text { text: sliderSlant.value.toFixed(2); color: "#00ffa3"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "✓ Recorte analítico G2 contínuo sem sub-janelas cortadas."
                        color: "#94a3b8"
                        font.pixelSize: 10
                        font.italic: true
                    }
                }

                // Divisor Vertical Transparente
                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: "#14ffffff"
                }

                // COLUNA 2: FÍSICA ÓPTICA & TELEMETRIA
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    Text {
                        text: "◈ FÍSICA ÓPTICA VALO GLASS"
                        color: "#00ffa3"
                        font.bold: true
                        font.pixelSize: 11
                        font.family: "JetBrains Mono, monospace"
                    }

                    // Slider IOR
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Índice Refração (IOR):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                        Slider {
                            id: sliderIOR
                            Layout.fillWidth: true
                            from: 1.00
                            to: 1.50
                            value: 1.20
                        }
                        Text { text: sliderIOR.value.toFixed(2); color: "#00ffa3"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Dispersão Cromática
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Dispersão (Cauchy):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                        Slider {
                            id: sliderDispersion
                            Layout.fillWidth: true
                            from: 0.000
                            to: 0.080
                            value: 0.040
                        }
                        Text { text: sliderDispersion.value.toFixed(3); color: "#ff007a"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Cáustica 45°
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Feixe Cáustico a 45°:"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                        Slider {
                            id: sliderCaustic
                            Layout.fillWidth: true
                            from: 0.00
                            to: 1.50
                            value: 0.50
                        }
                        Text { text: sliderCaustic.value.toFixed(2); color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Slider Opacidade Base
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Pigmento Abissal:"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                        Slider {
                            id: sliderOpacity
                            Layout.fillWidth: true
                            from: 0.00
                            to: 1.00
                            value: 0.40
                        }
                        Text { text: Math.round(sliderOpacity.value * 100) + "%"; color: "#f8fafc"; font.pixelSize: 11; Layout.preferredWidth: 36 }
                    }

                    // Caixa de Diagnóstico Transparente Unificada
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"
                        radius: 8
                        border.color: "#2500ffa3"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Text {
                                text: "DIAGNÓSTICO ÓPTICO SCREEN-SPACE [VK SPIR-V]"
                                color: "#94a3b8"
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "JetBrains Mono, monospace"
                            }

                            Text {
                                text: "• Ecrã Físico: " + Math.round(rootWindow.width * rootWindow.devicePixelRatio) + " × " + Math.round(rootWindow.height * rootWindow.devicePixelRatio) + " px (DPR: " + rootWindow.devicePixelRatio.toFixed(2) + ")"
                                color: "#cbd5e1"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono, monospace"
                            }

                            Text {
                                text: "• Prova de Fogo: Alfa = 1.0 (Refração Pura ativa)"
                                color: "#00ffa3"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono, monospace"
                            }

                            Text {
                                text: "• Menisco de Borda: 7.0 px (Zero Rubber Ring)"
                                color: "#00e5ff"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono, monospace"
                            }

                            Text {
                                text: "• Deflexão do Domo: Ativa e proporcional a (IOR - 1.0)"
                                color: "#ff007a"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono, monospace"
                            }

                            Text {
                                text: "• Posição da Placa: (" + Math.round(glassChassis.x) + ", " + Math.round(glassChassis.y) + ") — Arraste para inspecionar"
                                color: "#ffbe0b"
                                font.pixelSize: 10
                                font.family: "JetBrains Mono, monospace"
                            }
                        }
                    }
                }
            }
        }
    }
}
