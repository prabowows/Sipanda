import os
import joblib
import numpy as np
from xgboost import XGBRegressor
from sklearn.multioutput import MultiOutputRegressor

class SipandaMultivariateModel:
    """
    Multivariate Multi-Output Time-Series Forecasting Model for SIPANDA.
    Predicts:
      - Rainfall (mm) for T+1, T+2, T+3
      - Temperature (C) for T+1, T+2, T+3
      - Humidity (%) for T+1, T+2, T+3
    Total: 9 output variables simultaneously.
    """
    def __init__(self, best_params=None):
        if best_params is None:
            # Default robust hyperparameters
            self.params = {
                'n_estimators': 150,
                'max_depth': 5,
                'learning_rate': 0.05,
                'subsample': 0.8,
                'colsample_bytree': 0.8,
                'gamma': 0.1,
                'reg_alpha': 0.01,
                'reg_lambda': 1.0,
                'random_state': 42,
                'n_jobs': -1
            }
        else:
            self.params = best_params

        # Base XGBoost Regressor wrapped in MultiOutputRegressor
        self.base_estimator = XGBRegressor(**self.params)
        self.model = MultiOutputRegressor(self.base_estimator)
        self.is_fitted = False

    def fit(self, X, Y):
        """
        Fit model on training data.
        X shape: (N_samples, N_features)
        Y shape: (N_samples, 9) -> [rain_t1, rain_t2, rain_t3, temp_t1, temp_t2, temp_t3, hu_t1, hu_t2, hu_t3]
        """
        self.model.fit(X, Y)
        self.is_fitted = True

    def predict(self, X):
        """
        Predict multivariate 3-hour time-series.
        Returns:
          np.ndarray shape (N_samples, 9)
        """
        raw_pred = self.model.predict(X)
        
        # Post-processing physical boundaries:
        # Rainfall >= 0 mm
        raw_pred[:, 0:3] = np.clip(raw_pred[:, 0:3], 0.0, 200.0)
        # Temperature between 18.0 C and 42.0 C
        raw_pred[:, 3:6] = np.clip(raw_pred[:, 3:6], 18.0, 42.0)
        # Humidity between 20% and 100%
        raw_pred[:, 6:9] = np.clip(raw_pred[:, 6:9], 20.0, 100.0)
        
        return raw_pred

    def save(self, path=None):
        if path is None:
            path = os.path.join(os.path.dirname(__file__), 'model_latest.pkl')
        joblib.dump({
            'model': self.model,
            'params': self.params,
            'is_fitted': self.is_fitted
        }, path)
        print(f"[SIPANDA ML] Model successfully saved to: {path}")

    def load(self, path=None):
        if path is None:
            path = os.path.join(os.path.dirname(__file__), 'model_latest.pkl')
        if os.path.exists(path):
            data = joblib.load(path)
            self.model = data['model']
            self.params = data.get('params', self.params)
            self.is_fitted = data.get('is_fitted', True)
            print(f"[SIPANDA ML] Model loaded from: {path}")
            return True
        return False


def get_default_model_path():
    return os.path.join(os.path.dirname(__file__), 'model_latest.pkl')


def load_or_init_model():
    """
    Loads latest trained model if available,
    otherwise initializes and trains a baseline model on synthetic data.
    """
    model_obj = SipandaMultivariateModel()
    default_path = get_default_model_path()
    
    if model_obj.load(default_path):
        return model_obj
    
    # Initialize baseline dataset to bootstrap model
    print("[SIPANDA ML] No trained pickle found. Bootstrapping baseline model...")
    np.random.seed(42)
    n_samples = 100
    
    # Features: [rain, temp, hu, pressure, rain_lag1, temp_lag1, hu_lag1, rain_lag2, temp_lag2, hu_lag2, delta_rain]
    X_dummy = np.zeros((n_samples, 11))
    X_dummy[:, 0] = np.random.exponential(scale=8.0, size=n_samples) # Rain
    X_dummy[:, 1] = np.random.uniform(24.0, 33.0, size=n_samples)    # Temp
    X_dummy[:, 2] = np.random.uniform(65.0, 95.0, size=n_samples)    # Humidity
    X_dummy[:, 3] = np.random.uniform(995.0, 1015.0, size=n_samples) # Pressure
    X_dummy[:, 4] = np.maximum(0, X_dummy[:, 0] + np.random.normal(0, 2, size=n_samples))
    X_dummy[:, 5] = X_dummy[:, 1] + np.random.normal(0, 0.5, size=n_samples)
    X_dummy[:, 6] = np.clip(X_dummy[:, 2] + np.random.normal(0, 3, size=n_samples), 50, 100)
    X_dummy[:, 7] = np.maximum(0, X_dummy[:, 4] + np.random.normal(0, 2, size=n_samples))
    X_dummy[:, 8] = X_dummy[:, 5] + np.random.normal(0, 0.5, size=n_samples)
    X_dummy[:, 9] = np.clip(X_dummy[:, 6] + np.random.normal(0, 3, size=n_samples), 50, 100)
    X_dummy[:, 10] = X_dummy[:, 0] - X_dummy[:, 4] # Delta rain
    
    # Targets: [rain_t1, rain_t2, rain_t3, temp_t1, temp_t2, temp_t3, hu_t1, hu_t2, hu_t3]
    Y_dummy = np.zeros((n_samples, 9))
    Y_dummy[:, 0] = np.maximum(0, X_dummy[:, 0] * 1.1 + np.random.normal(0, 2, size=n_samples))
    Y_dummy[:, 1] = np.maximum(0, X_dummy[:, 0] * 0.9 + np.random.normal(0, 3, size=n_samples))
    Y_dummy[:, 2] = np.maximum(0, X_dummy[:, 0] * 0.7 + np.random.normal(0, 3, size=n_samples))
    
    Y_dummy[:, 3] = np.clip(X_dummy[:, 1] - 0.5 + np.random.normal(0, 0.5, size=n_samples), 20, 38)
    Y_dummy[:, 4] = np.clip(X_dummy[:, 1] - 0.8 + np.random.normal(0, 0.6, size=n_samples), 20, 38)
    Y_dummy[:, 5] = np.clip(X_dummy[:, 1] - 0.2 + np.random.normal(0, 0.5, size=n_samples), 20, 38)
    
    Y_dummy[:, 6] = np.clip(X_dummy[:, 2] + 2.0 + np.random.normal(0, 2, size=n_samples), 50, 100)
    Y_dummy[:, 7] = np.clip(X_dummy[:, 2] + 4.0 + np.random.normal(0, 3, size=n_samples), 50, 100)
    Y_dummy[:, 8] = np.clip(X_dummy[:, 2] + 1.0 + np.random.normal(0, 2, size=n_samples), 50, 100)
    
    model_obj.fit(X_dummy, Y_dummy)
    model_obj.save(default_path)
    return model_obj
