//
//  AnnotationManager.swift
//  SwiftScreenShot
//
//  Manages annotations with undo/redo support
//

import AppKit

class AnnotationManager {
    private var annotations: [Annotation] = []
    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []

    var onAnnotationsChanged: (() -> Void)?

    // MARK: - Annotation Management

    func addAnnotation(_ annotation: Annotation) {
        saveStateForUndo()
        annotations.append(annotation)
        redoStack.removeAll()
        notifyChange()
    }

    func removeAnnotation(_ annotation: Annotation) {
        saveStateForUndo()
        annotations.removeAll { $0.id == annotation.id }
        redoStack.removeAll()
        notifyChange()
    }

    func removeAnnotation(at point: CGPoint) -> Bool {
        // Find annotation at point (reverse order to get topmost)
        if let annotation = annotations.reversed().first(where: { $0.contains(point: point) }) {
            removeAnnotation(annotation)
            return true
        }
        return false
    }

    func getAnnotation(at point: CGPoint) -> Annotation? {
        return annotations.reversed().first { $0.contains(point: point) }
    }

    func getAllAnnotations() -> [Annotation] {
        return annotations
    }

    func clearAllAnnotations() {
        saveStateForUndo()
        annotations.removeAll()
        redoStack.removeAll()
        notifyChange()
    }

    // MARK: - Undo/Redo

    func undo() {
        guard !undoStack.isEmpty else { return }

        let currentState = annotations
        redoStack.append(currentState)

        annotations = undoStack.removeLast()
        notifyChange()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }

        let currentState = annotations
        undoStack.append(currentState)

        annotations = redoStack.removeLast()
        notifyChange()
    }

    var canUndo: Bool {
        return !undoStack.isEmpty
    }

    var canRedo: Bool {
        return !redoStack.isEmpty
    }

    // MARK: - Private Helpers

    private func saveStateForUndo() {
        // Deep copy annotations
        let stateCopy = annotations.map { annotation -> Annotation in
            if let arrow = annotation as? ArrowAnnotation {
                return ArrowAnnotation(
                    startPoint: arrow.startPoint,
                    endPoint: arrow.endPoint,
                    color: arrow.color,
                    lineWidth: arrow.lineWidth
                )
            } else if let text = annotation as? TextAnnotation {
                return TextAnnotation(
                    position: text.position,
                    text: text.text,
                    color: text.color,
                    fontSize: text.fontSize
                )
            } else if let rect = annotation as? RectangleAnnotation {
                return RectangleAnnotation(
                    rect: rect.rect,
                    color: rect.color,
                    lineWidth: rect.lineWidth,
                    fillColor: rect.fillColor,
                    cornerRadius: rect.cornerRadius
                )
            } else if let ellipse = annotation as? EllipseAnnotation {
                return EllipseAnnotation(
                    rect: ellipse.rect,
                    color: ellipse.color,
                    lineWidth: ellipse.lineWidth,
                    fillColor: ellipse.fillColor
                )
            } else {
                return annotation
            }
        }

        undoStack.append(stateCopy)

        // Limit undo stack size to prevent memory issues
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    private func notifyChange() {
        onAnnotationsChanged?()
    }
}
