import numpy as np
from sklearn.metrics import mean_squared_error, accuracy_score, precision_score, recall_score, f1_score

def evaluate_classification(y_true, y_pred):
    """
    Evaluasi performa model klasifikasi risiko banjir (Aman, Waspada, Siaga)
    """
    accuracy = accuracy_score(y_true, y_pred)
    # Gunakan 'weighted' atau 'macro' untuk multiclass classification
    precision = precision_score(y_true, y_pred, average='weighted', zero_division=0)
    recall = recall_score(y_true, y_pred, average='weighted', zero_division=0)
    f1 = f1_score(y_true, y_pred, average='weighted', zero_division=0)
    
    print("=== Laporan Evaluasi Model Klasifikasi Risiko ===")
    print(f"Accuracy  : {accuracy:.4f}")
    print(f"Precision : {precision:.4f}")
    print(f"Recall    : {recall:.4f}")
    print(f"F1-Score  : {f1:.4f}")
    
    return {
        'accuracy': accuracy,
        'precision': precision,
        'recall': recall,
        'f1_score': f1
    }

def evaluate_regression(y_actual_rainfall, y_pred_rainfall):
    """
    Evaluasi model regresi untuk memprediksi metrik curah hujan spesifik (jika ada) menggunakan RMSE
    """
    rmse = np.sqrt(mean_squared_error(y_actual_rainfall, y_pred_rainfall))
    
    print("=== Laporan Evaluasi Regresi Curah Hujan ===")
    print(f"RMSE : {rmse:.4f}")
    
    return {'rmse': rmse}

if __name__ == "__main__":
    # Contoh penggunaan mock
    # 0 = Aman, 1 = Waspada, 2 = Siaga
    y_true_mock = [0, 1, 2, 0, 1, 2, 2, 1, 0, 0]
    y_pred_mock = [0, 1, 1, 0, 1, 2, 2, 2, 0, 0]
    
    evaluate_classification(y_true_mock, y_pred_mock)
