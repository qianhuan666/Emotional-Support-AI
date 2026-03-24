document.addEventListener("DOMContentLoaded", () => {
    const menuToggle = document.querySelector("[data-menu-toggle]");
    const navLinks = document.querySelector("[data-nav-links]");

    if (menuToggle && navLinks) {
        menuToggle.addEventListener("click", () => {
            navLinks.classList.toggle("open");
            menuToggle.setAttribute("aria-expanded", navLinks.classList.contains("open") ? "true" : "false");
        });
    }
});
