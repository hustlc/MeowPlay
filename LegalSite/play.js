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
const translatorForm = document.querySelector("#translator-form");
const translatorMessage = document.querySelector("#translator-message");
const translatorPlay = document.querySelector("#translator-play");
let translatedCard = null;

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

function chooseTranslation(phrase) {
  const text = phrase.toLowerCase();
  const rules = [
    { words: ["come", "here", "过来", "来", "跟我"], categories: ["Come Here"], titles: ["Come Here", "Follow Me", "This Way, Friend"] },
    { words: ["play", "玩", "游戏", "fun", "玩耍"], categories: ["Play Time"], titles: ["Play With Me"] },
    { words: ["food", "eat", "dinner", "snack", "饭", "吃", "饿", "零食"], categories: ["Food Time"], titles: ["Snack Time", "Dinner Is Ready"] },
    { words: ["love", "cute", "hug", "cuddle", "爱", "可爱", "抱", "摸"], categories: ["Affection"], titles: ["I'm Mom", "You Are So Cute", "Cuddle With Me"] },
    { words: ["look", "listen", "hear", "attention", "看", "听", "注意"], categories: ["Attention"], titles: ["Look at Me", "Can You Hear Me?", "A Little Attention"] },
    { words: ["what", "who", "curious", "什么", "谁", "好奇"], categories: ["Curious & Social"], titles: ["What's That?"] }
  ];
  const rule = rules.find((candidate) => candidate.words.some((word) => text.includes(word)));
  const candidates = rule
    ? state.cards.filter((card) => rule.categories.includes(card.category) || rule.titles.includes(card.title))
    : state.cards.filter((card) => card.safetyTag === "gentle" || card.safetyTag === "neutral");
  return candidates[Math.floor(Math.random() * candidates.length)] || state.cards[0];
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

translatorForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const phrase = new FormData(translatorForm).get("phrase").trim();
  if (!phrase || !state.cards.length) return;
  translatedCard = chooseTranslation(phrase);
  translatorMessage.textContent = `“${phrase}” becomes “${translatedCard.title}” in playful cat-sound mode.`;
  translatorPlay.hidden = false;
  setStatus("A playful interpretation is ready.");
});

translatorPlay.addEventListener("click", () => {
  if (translatedCard) playCard(translatedCard);
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
