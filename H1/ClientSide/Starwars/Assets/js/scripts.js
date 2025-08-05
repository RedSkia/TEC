let people;
let planets;
let films;
async function fetchData(apiUrl) {
    try {
        const response = await fetch(apiUrl);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        console.log('Data fetched:', data);
        return data;
    } catch (error) {
        console.error('Error fetching data:', error);
        return null;
    }
}
function openModal(text) {
    document.getElementById('modalText').textContent = text;
    document.getElementById('modal').style.display = 'block';
}
function closeModal() {
    document.getElementById('modal').style.display = 'none';
}
function AddOptions(selector, array) {
    const DATA_LIST = document.querySelector(selector);
    DATA_LIST.innerHTML = '';
    array.forEach(x => {
        const option = document.createElement('option');
        option.value = x;
        option.textContent = x;
        DATA_LIST.appendChild(option);
    });
}

function SearchPeople() {
    const query = document.getElementById('peopleSearch').value.toLowerCase();
    const filteredPeople = people.filter(person => person.name.toLowerCase().includes(query));
    ShowPeople(filteredPeople);
}
function ShowPeople(array) {
    const nav = document.querySelector('#container > .people');
    
    const existingUl = nav.querySelector('ul');
    if (existingUl) {
        nav.removeChild(existingUl);
    }

    const ul = document.createElement('ul');
    array.forEach(person => {
        const li = document.createElement('li');
        li.textContent = person.name;
        
        const nestedUl = document.createElement('ul');
        nestedUl.classList.add('nested');

        const heightLi = document.createElement('li');
        heightLi.textContent = `Height: ${person.height}`;
        nestedUl.appendChild(heightLi);

        const birthyearLi = document.createElement('li');
        birthyearLi.textContent = `Birth Year: ${person.birth_year}`;
        nestedUl.appendChild(birthyearLi);

        const genderLi = document.createElement('li');
        genderLi.textContent = `Gender: ${person.gender}`;
        nestedUl.appendChild(genderLi);

        li.appendChild(nestedUl);
        ul.appendChild(li);
    });
    nav.appendChild(ul);
}

function ShowPlanets(array) {
    const data = typeof planets !== 'undefined' && planets.length > 0 ? planets : array;
    if (!data || data.length === 0) {
        console.error("No planets data available.");
        return;
    }

    const climateDropdown = document.querySelector('.planets > #suggestions');
    const selectedClimate = climateDropdown.value.toLowerCase();
    
    const climate = selectedClimate || data[0].climate.toLowerCase();
    
    console.log('Selected climate:', climate);

    const planetsFilter = data.filter(planet => planet.climate.toLowerCase() === climate);
    console.log('Selected planets:', planetsFilter);

    const nav = document.querySelector('#container > .planets');
    
    const existingUl = nav.querySelector('ul');
    if (existingUl) {
        nav.removeChild(existingUl);
    }

    const ul = document.createElement('ul');
    planetsFilter.forEach(planet => {
        const li = document.createElement('li');
        li.textContent = planet.name;

        const nestedUl = document.createElement('ul');
        nestedUl.classList.add('nested');

        const heightLi = document.createElement('li');
        heightLi.textContent = `Population: ${planet.population}`;
        nestedUl.appendChild(heightLi);

        const birthyearLi = document.createElement('li');
        birthyearLi.textContent = `Climate: ${planet.climate}`;
        nestedUl.appendChild(birthyearLi);

        const genderLi = document.createElement('li');
        genderLi.textContent = `Terrain: ${planet.terrain}`;
        nestedUl.appendChild(genderLi);

        li.appendChild(nestedUl);
        ul.appendChild(li);
    });

    nav.appendChild(ul);
}
function ShowFilms(array) {
    const nav = document.querySelector('#container > .films');
    
    const existingUl = nav.querySelector('ul');
    if (existingUl) {
        nav.removeChild(existingUl);
    }

    const ul = document.createElement('ul');
    array.forEach(film => {
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.textContent = film.title;
        a.setAttribute('href', 'javascript:void(0)');
        a.setAttribute('onclick', `openModal('${film.opening_crawl.replace(/[.\n'\s]+/g, ' ')}')`);

        li.appendChild(a);
        
        const nestedUl = document.createElement('ul');
        nestedUl.classList.add('nested');

        const heightLi = document.createElement('li');
        heightLi.textContent = `Release date: ${film.release_date}`;
        nestedUl.appendChild(heightLi);

        li.appendChild(nestedUl);
        ul.appendChild(li);
    });
    nav.appendChild(ul);
}

const element1 = document.querySelector('#container > .people');
const element2 = document.querySelector('#container > .planets');
const element3 = document.querySelector('#container > .films');
const elementPlaceholder = document.querySelector('#container > p:first-child');
function DisplayPeople() {
    element1.style.display = 'block'; 
    element2.style.display = 'none';
    element3.style.display = 'none';
    elementPlaceholder.style.display = 'none';
}
function DisplayPlanets() {
    element1.style.display = 'none'; 
    element2.style.display = 'block';
    element3.style.display = 'none';
    elementPlaceholder.style.display = 'none';
}
function DisplayFilms() {
    element1.style.display = 'none'; 
    element2.style.display = 'none';
    element3.style.display = 'block';
    elementPlaceholder.style.display = 'none';
}

window.onload = () => {
    fetchData("https://swapi.py4e.com/api/people/").then(data => {
        if (data) {
            people = data.results;
            console.log('Fetched data stored in variable:', data);
        }
        ShowPeople(people);
        AddOptions('.people > #suggestions', [...new Set(people.flatMap(person => person.name))]);
    });
    fetchData("https://swapi.py4e.com/api/planets/").then(data => {
        if (data) {
            planets = data.results;
            console.log('Fetched data stored in variable:', data);
        }
        ShowPlanets(planets);
        AddOptions('.planets > #suggestions', [...new Set(planets.flatMap(planet => planet.climate))]);
    });
    fetchData("https://swapi.py4e.com/api/films/").then(data => {
        if (data) {
            films = data.results;
            console.log('Fetched data stored in variable:', data);
        }
        ShowFilms(films);
    });
};