# Diagram Snippets & Menu Rules

`zago` provides a contextual **Diagram Snippets** system that helps you quickly insert starter templates for **Mermaid**, **PlantUML**, and **Graphviz (DOT)** diagrams without having to memorize their syntax initialization headers.

---

## 🎯 Trigger Conditions & Menu Visibility

The `Diagrams` menu category appears dynamically in the top **MenuBar** between **Tools** and **Help** (`File | Edit | Buffer | Shapes | Borders | Tools | Diagrams | Help`) based on your current buffer context:

| Context / Location | Menu Visibility | Menu Item Filtering |
|---|---|---|
| **Outside any code block** in `.md`, `.org`, `.rst`, or plain text | ❌ Hidden | N/A |
| **Inside generic code block (` ``` `)** without language tag | ✅ Visible | Displays **ALL** 13 diagram types (Mermaid, PlantUML, DOT) |
| **Inside Mermaid code block (` ```mermaid `)** or `.mermaid` / `.mmd` file | ✅ Visible | Filters and displays **ONLY Mermaid** diagram snippets |
| **Inside PlantUML code block (` ```puml `)** or `.puml` / `.plantuml` file | ✅ Visible | Filters and displays **ONLY PlantUML** diagram snippets |
| **Inside Graphviz code block (` ```dot `)** or `.dot` / `.gv` file | ✅ Visible | Filters and displays **ONLY Graphviz (DOT)** diagram snippets |

---

## 📊 Supported Diagram Engines & Templates

### 1. Mermaid Snippets

* **Sequence Diagram** (`sequenceDiagram`)
* **Flowchart** (`flowchart TD`)
* **Class Diagram** (`classDiagram`)
* **State Diagram** (`stateDiagram-v2`)
* **ER Diagram** (`erDiagram`)
* **Mindmap** (`mindmap`)

### 2. PlantUML Snippets

* **Sequence Diagram** (`@startuml ... @enduml`)
* **Flowchart / Activity Diagram** (`@startuml ... @enduml`)
* **Class Diagram** (`@startuml ... @enduml`)
* **State Diagram** (`@startuml ... @enduml`)
* **ER Diagram** (`@startuml ... @enduml`)

### 3. Graphviz (DOT) Snippets

* **Directed Graph** (`digraph G { ... }`)
* **Undirected Graph** (`graph G { ... }`)

---

## ⌨️ Command Prompt (`Esc`) Usage

You can also trigger diagram snippets directly from the LOGO Command Prompt (press `Esc`):

* `DIAGRAM` or `SNIPPET`: Opens the MenuBar positioned at the `Diagrams` category.
* `DIAGRAM "sequence`: Inserts the Sequence Diagram snippet directly.
* `DIAGRAM "flowchart`: Inserts the Flowchart snippet directly.
* `DIAGRAM "digraph`: Inserts the Graphviz Directed Graph snippet directly.

---

## 💡 Context-Aware Snippet Wrapping

* **Inside dedicated code blocks or diagram files**: Inserts the template body directly at your cursor without duplicate fenced code block wrappers.
* **Via command prompt when outside code blocks**: Automatically wraps the inserted snippet in the appropriate fenced code block (` ```mermaid `, ` ```puml `, or ` ```dot `).
