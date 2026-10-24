import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Systalia.Engine 1.0

ApplicationWindow {
    id: root
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

            // Padrão xadrez de alta frequência para evidenciar refração analítica
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
                x: -100 + (animTimer.tick * 80) % (root.width + 800) - 400
                y: root.height - 80
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

    // Timer para animação fluida do fundo (60 FPS)
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
    // 2. CAPTURA DO BACKDROP DIRETAMENTE SOB A JANELA DE VIDRO
    // =========================================================================
    ShaderEffectSource {
        id: backdropSource
        sourceItem: backgroundScene
        sourceRect: Qt.rect(glassWindow.x, glassWindow.y, glassWindow.width, glassWindow.height)
        recursive: false
        live: true
        hideSource: false
    }

    // =========================================================================
    // 3. JANELA INTERATIVA VALO GLASS COM MOTOR ÓPTICO SDF
    // =========================================================================
    Item {
        id: glassWindow
        width: 820
        height: 580
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        // 3.1 SUPERFÍCIE ÓPTICA SGE (C++ QQuickItem / Vulkan RHI)
        SystaliaGlassItem {
            id: opticalSurface
            anchors.fill: parent
            sourceItem: backdropSource

            // Propriedades std140 sincronizadas com controlos
            radii: Qt.vector4d(sliderRTL.value, sliderRTR.value, sliderRBL.value, sliderRBR.value)
            slant: sliderSlant.value
            ior: sliderIOR.value
            chromaticDispersion: sliderDispersion.value
            causticIntensity: sliderCaustic.value
            surfaceOpacity: sliderOpacity.value
        }

        // 3.2 CAMADA DE CONTEÚDO E CONTROLOS DA JANELA
        Item {
            anchors.fill: parent
            clip: false

            // Barra de Título (Titlebar) com suporte a Drag da Janela
            Rectangle {
                id: titleBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 48
                color: "transparent"

                DragHandler {
                    id: windowDrag
                    target: glassWindow
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    spacing: 12

                    // Ícone do Systalia Glass Engine
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 6
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

                    // Título e Status
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
                            text: "Fase 1: Motor Óptico Analítico • Vulkan RHI Native • Subpixel G2"
                            color: "#00e5ff"
                            font.pixelSize: 10
                            font.family: "JetBrains Mono, monospace"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Badges de Telemetria Ativa
                    Rectangle {
                        height: 22
                        width: 80
                        radius: 4
                        color: "#2600e5ff"
                        border.color: "#6600e5ff"
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
                        height: 22
                        width: 65
                        radius: 4
                        color: "#2600ffa3"
                        border.color: "#6600ffa3"
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

                    // Controles de Janela (Botões estilo Systalia)
                    Row {
                        spacing: 8
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "#22c55e"
                            border.color: "#4dffffff"
                        }
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "#eab308"
                            border.color: "#4dffffff"
                        }
                        Rectangle {
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "#ef4444"
                            border.color: "#4dffffff"
                        }
                    }
                }
            }

            // Separador sutil
            Rectangle {
                anchors.top: titleBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                height: 1
                color: "#1affffff"
            }

            // Painel Principal de Controlo e Telemetria
            RowLayout {
                anchors.top: titleBar.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 18
                spacing: 20

                // COLUNA ESQUERDA: Sliders dos 4 Raios Analíticos e Presets
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 380
                    color: "#8c08101c"
                    radius: 12
                    border.color: "#4000e5ff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "CONTROLO DE CURVATURA SDF (G2 SQUIRCLE)"
                            color: "#00e5ff"
                            font.bold: true
                            font.pixelSize: 11
                            font.family: "JetBrains Mono, monospace"
                        }

                        // Presets Rápidos
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
                                    color: parent.hovered ? "#4d00e5ff" : "#1f00e5ff"
                                    radius: 5
                                    border.color: "#6600e5ff"
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
                                    color: parent.hovered ? "#4d00ffa3" : "#1f00ffa3"
                                    radius: 5
                                    border.color: "#6600ffa3"
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
                                    color: parent.hovered ? "#4dff007a" : "#1fff007a"
                                    radius: 5
                                    border.color: "#66ff007a"
                                }
                                onClicked: {
                                    sliderRTL.value = 40;
                                    sliderRTR.value = 6;
                                    sliderRBL.value = 8;
                                    sliderRBR.value = 40;
                                }
                            }
                        }

                        // Slider Top-Left
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Raio Sup. Esq. (r_tl):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                            Slider {
                                id: sliderRTL
                                Layout.fillWidth: true
                                from: 0.0
                                to: 64.0
                                value: 24.0
                            }
                            Text { text: Math.round(sliderRTL.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Top-Right
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Raio Sup. Dir. (r_tr):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                            Slider {
                                id: sliderRTR
                                Layout.fillWidth: true
                                from: 0.0
                                to: 64.0
                                value: 24.0
                            }
                            Text { text: Math.round(sliderRTR.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Bottom-Left
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Raio Inf. Esq. (r_bl):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                            Slider {
                                id: sliderRBL
                                Layout.fillWidth: true
                                from: 0.0
                                to: 64.0
                                value: 24.0
                            }
                            Text { text: Math.round(sliderRBL.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Bottom-Right
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Raio Inf. Dir. (r_br):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                            Slider {
                                id: sliderRBR
                                Layout.fillWidth: true
                                from: 0.0
                                to: 64.0
                                value: 24.0
                            }
                            Text { text: Math.round(sliderRBR.value) + "px"; color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Slant / Trapézio
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Inclinação (Slant/Domo):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 150 }
                            Slider {
                                id: sliderSlant
                                Layout.fillWidth: true
                                from: -0.8
                                to: 0.8
                                value: 0.0
                            }
                            Text { text: sliderSlant.value.toFixed(2); color: "#00ffa3"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        Item { Layout.fillHeight: true }

                        // Aviso de conformidade
                        Text {
                            text: "✓ Recorte analítico G2 sem QRegion nem blur bleed."
                            color: "#94a3b8"
                            font.pixelSize: 10
                            font.italic: true
                        }
                    }
                }

                // COLUNA DIREITA: Simulação Óptica (IOR, Dispersão, Cáustica, Opacidade)
                Rectangle {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: "#8c08101c"
                    radius: 12
                    border.color: "#4000ffa3"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Text {
                            text: "PARÂMETROS ÓPTICOS VALO GLASS"
                            color: "#00ffa3"
                            font.bold: true
                            font.pixelSize: 11
                            font.family: "JetBrains Mono, monospace"
                        }

                        // Slider IOR (Índice de Refração)
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Índice Refração (IOR):"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 160 }
                            Slider {
                                id: sliderIOR
                                Layout.fillWidth: true
                                from: 1.00
                                to: 1.45
                                value: 1.12
                            }
                            Text { text: sliderIOR.value.toFixed(2); color: "#00ffa3"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Dispersão Cromática (Cauchy)
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Dispersão Cromática:"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 160 }
                            Slider {
                                id: sliderDispersion
                                Layout.fillWidth: true
                                from: 0.000
                                to: 0.060
                                value: 0.025
                            }
                            Text { text: sliderDispersion.value.toFixed(3); color: "#ff007a"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Intensidade Cáustica 45°
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Feixe Cáustico a 45°:"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 160 }
                            Slider {
                                id: sliderCaustic
                                Layout.fillWidth: true
                                from: 0.00
                                to: 1.50
                                value: 0.65
                            }
                            Text { text: sliderCaustic.value.toFixed(2); color: "#00e5ff"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Slider Opacidade
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Opacidade Global:"; color: "#cbd5e1"; font.pixelSize: 11; Layout.preferredWidth: 160 }
                            Slider {
                                id: sliderOpacity
                                Layout.fillWidth: true
                                from: 0.20
                                to: 1.00
                                value: 1.00
                            }
                            Text { text: Math.round(sliderOpacity.value * 100) + "%"; color: "#f8fafc"; font.pixelSize: 11; Layout.preferredWidth: 38 }
                        }

                        // Painel de Telemetria Óptica em tempo real
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#99030712"
                            radius: 8
                            border.color: "#14ffffff"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                Text {
                                    text: "DIAGNÓSTICO EM TEMPO REAL [VK SPIR-V]"
                                    color: "#94a3b8"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.family: "JetBrains Mono, monospace"
                                }

                                Text {
                                    text: "• Dimensões Janela: " + Math.round(glassWindow.width) + " × " + Math.round(glassWindow.height) + " px"
                                    color: "#cbd5e1"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono, monospace"
                                }

                                Text {
                                    text: "• Menisco de Borda: 7.0 px (Restrito: Elimina Rubber Ring)"
                                    color: "#00ffa3"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono, monospace"
                                }

                                Text {
                                    text: "• Specular Rim: 1.1 px (Zênite estrito -norm.y > 0.0)"
                                    color: "#00e5ff"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono, monospace"
                                }

                                Text {
                                    text: "• Anti-Aliasing: Analítico subpixel com fwidth(dist)"
                                    color: "#f8fafc"
                                    font.pixelSize: 10
                                    font.family: "JetBrains Mono, monospace"
                                }

                                Text {
                                    text: "• Posição: (" + Math.round(glassWindow.x) + ", " + Math.round(glassWindow.y) + ") — Arraste a barra para reposicionar"
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
}
