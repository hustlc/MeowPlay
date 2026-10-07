const state = {
  cards: [],
  category: "All",
  favoritesOnly: false,
  favorites: new Set(JSON.parse(localStorage.getItem("meowplay-favorites") || "[]")),
  audio: new Audio()
};

const grid = document.querySelector("#sound-grid");
const tabs = document.querySelector("#category-tabs");
const statusLine = document.querySelector("#status-line");
const favoritesToggle = document.querySelector("#favorites-toggle");

function saveFavorites() {
  localStorage.setItem("meowplay-favorites", JSON.stringify([...state.favorites]));
}

function setStatus(message) {
  statusLine.textContent = message;
}

function visibleCards() {
  return state.cards.filter((card) => {
    const categoryMatches = state.category === "All" || card.category === state.category;
    const favoriteMatches = !state.favoritesOnly || state.favorites.has(card.id);
    return categoryMatches && favoriteMatches;
  });
}

function renderTabs() {
  const categories = ["All", ...new Set(state.cards.map((card) => card.category))];
  tabs.innerHTML = categories.map((category) => `
    <button class="tab ${state.category === category ? "is-active" : ""}" type="button"
      data-category="${category}" aria-pressed="${state.category === category}">
      ${category}
    </button>
  `).join("");
}

function renderCards() {
  const cards = visibleCards();
  if (!cards.length) {
    grid.innerHTML = `<p class="empty-state">No favorites here yet. Tap the heart on a sound to keep it close.</p>`;
    return;
  }

  grid.innerHTML = cards.map((card) => {
    const favorite = state.favorites.has(card.id);
    return `
      <article class="sound-card">
        <div class="sound-card-top">
          <span class="sound-category">${card.category}</span>
          <button class="favorite-button ${favorite ? "is-favorite" : ""}" type="button"
            data-favorite="${card.id}" aria-label="${favorite ? "Remove" : "Add"} ${card.title} ${favorite ? "from" : "to"} favorites"
            aria-pressed="${favorite}">${favorite ? "♥" : "♡"}</button>
        </div>
        <h2>${card.title}</h2>
        <p>${card.tier === "free" ? "Free sound" : "Available in the launch collection"}</p>
        <button class="play-button" type="button" data-play="${card.id}">
          <span aria-hidden="true">▶</span><span>Play once</span>
        </button>
      </article>
    `;
  }).join("");
}

function playCard(card) {
  state.audio.pause();
  state.audio.currentTime = 0;
  state.audio.src = `audio/${encodeURIComponent(card.assetName)}`;
  state.audio.volume = 0.55;
  state.audio.play().then(() => {
    setStatus(`Playing “${card.title}”.`);
  }).catch(() => {
    setStatus("Tap Play once again to start the sound.");
  });
}

tabs.addEventListener("click", (event) => {
  const button = event.target.closest("[data-category]");
  if (!button) return;
  state.category = button.dataset.category;
  renderTabs();
  renderCards();
});

favoritesToggle.addEventListener("click", () => {
  state.favoritesOnly = !state.favoritesOnly;
  favoritesToggle.setAttribute("aria-pressed", String(state.favoritesOnly));
  favoritesToggle.classList.toggle("is-active", state.favoritesOnly);
  setStatus(state.favoritesOnly ? "Showing your favorites." : "Showing all sounds.");
  renderCards();
});

grid.addEventListener("click", (event) => {
  const favoriteButton = event.target.closest("[data-favorite]");
  if (favoriteButton) {
    const id = favoriteButton.dataset.favorite;
    if (state.favorites.has(id)) state.favorites.delete(id);
    else state.favorites.add(id);
    saveFavorites();
    renderCards();
    return;
  }

  const playButton = event.target.closest("[data-play]");
  if (playButton) {
    const card = state.cards.find((item) => item.id === playButton.dataset.play);
    if (card) playCard(card);
  }
});

fetch("sound-catalog.json")
  .then((response) => {
    if (!response.ok) throw new Error("Catalog unavailable");
    return response.json();
  })
  .then((cards) => {
    state.cards = cards.sort((a, b) => a.sortOrder - b.sortOrder);
    renderTabs();
    renderCards();
  })
  .catch(() => {
    setStatus("The soundboard is temporarily unavailable. Please try again soon.");
  });
