from flask import Flask, request, jsonify
from flask_restful import Resource, Api
import pandas as pd
import numpy as np
from scipy.stats import pearsonr
import matplotlib.pyplot as plt
from sklearn.metrics import f1_score, accuracy_score, auc#, balanced_accuracy_score
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold
from sklearn.preprocessing import MinMaxScaler

'''

Data is from https://www.wunderground.com/history/daily/KBDL/date/2022-8-19


'''

pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)

data_raw = pd.read_excel('NewWeatherData.xlsx')

cleanup_nums = {'SchoolClosed': {'No': 0, 'Yes': 1}}

data_raw.replace(cleanup_nums, inplace=True)

print(data_raw.shape)


def calculate_pvalues(df):
    df = df.dropna()._get_numeric_data()
    dfcols = pd.DataFrame(columns=df.columns)
    pvalues = dfcols.transpose().join(dfcols, how='outer')
    for r in df.columns:
        for c in df.columns:
            pvalues[r][c] = round(pearsonr(df[r], df[c])[1], 4)
    return pvalues

data = data_raw.dropna()
print(data)
calculate_pvalues(data)

y = data['SchoolClosed'].values

features = np.array(['Max', 'Min', 'Dew', 'Humidity', 'WindSpeed', 'Precipitation'])
X = data[features].values
#features = data.drop(['NEC episode I'], axis=1).columns
print("shape of X:", X.shape, "shape of y", y.shape) 
X = X.astype(float)
y = y.astype(float)

app = Flask(__name__)
objapi = Api(app)

scaler = MinMaxScaler()
clf = LogisticRegression(class_weight={1:25, 0:1}, solver='lbfgs')
skf = StratifiedKFold(n_splits=3)
for train, test in skf.split(X, y):
    scaler.fit(X[train])
    clf.fit(scaler.transform(X[train]), y[train])
    Y_test_pred = clf.predict(scaler.transform(X[test]))
    test_f1 = f1_score(y[test], Y_test_pred)
    test_acc = accuracy_score(y[test], Y_test_pred)
    #test_auc = auc(y[test], Y_test_pred)
    #test_accb = balanced_accuracy_score(y[test], Y_test_pred)
    print("F1 Score", test_f1, "Accuracy", test_acc)#, "Auc", test_auc)#, "Balanced Accuracy", test_accb)
    #print(np.argsort(np.abs(np.std(scaler.transform(X[train]), 0)*clf.coef_[0]))[::-1])
    print(clf.coef_[0])
    print(np.abs(np.std(scaler.transform(X[train]), 0)*clf.coef_[0]))
    print("Feature Importance:", features[np.argsort(np.abs(np.std(scaler.transform(X[train]), 0)*clf.coef_[0]))][::-1])



class getData(Resource):
    def get(self, intMax, intMin, intDew, intHumidity, intWS, intPrecip):

        #[28, 1240, 1.0, 0, 8, 0, 0, 0.0, 0, 0, 0, 0, 0, 1]
        userData_arr = []
        
        arr = [[intMax, intMin, intDew, intHumidity, intWS, intPrecip]]
        
        Y_pred = clf.predict_proba(scaler.transform(arr))
        
        userData = {}
        print(Y_pred)
        
        userData["id"] = 0
        userData["Score"] = Y_pred[0][0]
        userData_arr.append(userData)

        response = jsonify(userData_arr)
        response.headers.add('Access-Control-Allow-Origin', '*')


        
        return response


objapi.add_resource(getData, "/getData/<intMax>/<intMin>/<intDew>/<intHumidity>/<intWS>/<intPrecip>")

#app.run(debug=True)
app.run(host='0.0.0.0', port=900)
