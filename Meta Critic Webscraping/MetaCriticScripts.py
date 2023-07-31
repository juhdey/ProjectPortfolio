import requests, openpyxl
from bs4 import BeautifulSoup


excel = openpyxl.Workbook()
sheet = excel.active
sheet.title = "Video Game Rankings"
sheet.append(['Name', 'Year', 'Platform', 'Rating'])

try: 
    for i in range(0, 205):
        userAgent = {'User-agent': 'Mozilla/5.0'}
        url = f"https://www.metacritic.com/browse/games/score/metascore/all/all/filtered?page={i}"
        website = requests.get(url,headers=userAgent)
        website.raise_for_status()
        
        soup = BeautifulSoup(website.text, 'html.parser')

        games = soup.find('div', class_='title_bump').find_all('tr', class_='')

        for game in games:
            name = game.find('td', class_='clamp-summary-wrap').find('a', class_='title').text

            platform = game.find('td', class_='clamp-summary-wrap').find('div', class_='clamp-details').div.find('span', class_='data').text.strip()

            year = game.find('td', class_='clamp-summary-wrap').find('div', class_='clamp-details').find('span', class_='').text.split(',')[1].strip()

            rating = game.find('td', class_='clamp-summary-wrap').find('div', class_='clamp-score-wrap').a.div.text
            sheet.append([name, year, platform, rating])

        # print(len(games))
except Exception as e:
    print(e)

excel.save('videogameranks.xlsx')
