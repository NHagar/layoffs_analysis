import pandas as pd
import spacy
nlp = spacy.load("en_core_web_lg")

def gen_spacy_embeddings(data):
    data['embeds'] = data['text_body'].apply(lambda x: nlp(x).vector)
    embed_dims = data['embeds'].apply(pd.Series)
    embeddings = pd.concat([data['text_body'], embed_dims[:]], axis=1)

    return embeddings
