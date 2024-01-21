import pandas as pd

df = pd.read_csv("Yammer_event_countries.csv")

continents = df["Continent"].unique()
for continent in continents:
    countries = df.loc[df["Continent"] == continent, "location"]
    print(f"{continent}:  {list(countries.values)}")