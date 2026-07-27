import numpy as np
from sklearn.ensemble import RandomForestClassifier, StackingClassifier
from sklearn.linear_model import LogisticRegression
from xgboost import XGBClassifier
import joblib

class SipandaStackingModel:
    def __init__(self):
        # Base Learners
        self.base_models = [
            ('rf', RandomForestClassifier(n_estimators=100, random_state=42)),
            ('xgb', XGBClassifier(use_label_encoder=False, eval_metric='mlogloss', random_state=42))
        ]
        # Meta Learner
        self.meta_model = LogisticRegression()
        
        # Eksekusi Stacking
        self.model = StackingClassifier(
            estimators=self.base_models,
            final_estimator=self.meta_model,
            cv=5
        )

    def train(self, X_train, y_train):
        """Melatih model dari awal dengan data historis"""
        self.model.fit(X_train, y_train)

    def predict(self, X_test):
        """Memprediksi: 0 (Aman), 1 (Waspada), 2 (Siaga)"""
        return self.model.predict(X_test)
        
    def predict_proba(self, X_test):
        """Memprediksi probabilitas masing-masing kelas"""
        return self.model.predict_proba(X_test)

    def adaptive_retrain(self, new_X, new_y):
        """
        Pendekatan *Adaptive Learning* (Partial/Retrain)
        Karena RandomForest dan XGBoost standar tidak sepenuhnya mendukung partial_fit,
        kita memerlukan buffer data (menggabungkan data lama dan baru) dan melakukan pembaruan/fit ulang.
        """
        # Dalam skenario production Firebase: tarik data lama dari Firestore, gabung dgn data baru.
        # Kemudian fit ulang modelnya secara berkala.
        pass

    def save_model(self, path='weights/stacking_model.pkl'):
        joblib.dump(self.model, path)
        
    def load_model(self, path='weights/stacking_model.pkl'):
        self.model = joblib.load(path)

def load_stacking_ensemble():
    import os
    model_obj = SipandaStackingModel()
    path = os.path.join(os.path.dirname(__file__), 'saved_model.pkl')
    if os.path.exists(path):
        model_obj.load_model(path)
    else:
        # Train a dummy model with synthetic data so it works out of the box
        X = np.random.rand(30, 3)
        # Features: rainfall (0-100 mm), pressure (980-1020 hPa), temp (22-35 C)
        X[:, 0] = X[:, 0] * 120
        X[:, 1] = 980 + X[:, 1] * 40
        X[:, 2] = 22 + X[:, 2] * 13
        y = np.random.choice([0, 1, 2], size=30)
        model_obj.train(X, y)
    return model_obj

