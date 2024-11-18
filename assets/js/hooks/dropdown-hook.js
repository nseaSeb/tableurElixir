// assets/js/hooks/dropdown_hook.js
const DropdownHook = {
    mounted() {
        // Récupérer l'index de la ligne depuis le data attribute
        this.rowIndex = this.el.dataset.rowIndex;
        this.triggerBtn = this.el.querySelector('[data-dropdown-trigger]');

        // Construire l'id du menu correspondant
        this.menu = document.getElementById(`menu${this.rowIndex}`);

        if (!this.menu) {
            console.warn(`Menu #menu${this.rowIndex} not found`);
            return;
        }

        // Positionner le menu en absolu par rapport au viewport
        // this.menu.style.position = 'fixed';
        // this.menu.style.top = this.triggerBtn.style.top;
        this.menu.style.display = 'none';

        this.handleClick = this.handleClick.bind(this);
        this.handleClickOutside = this.handleClickOutside.bind(this);

        this.triggerBtn.addEventListener('click', this.handleClick);
    },

    handleClick(e) {
        e.stopPropagation();

        const allMenus = document.querySelectorAll('.dropdown-menu');
        // Fermer tous les autres menus
        allMenus.forEach((menu) => {
            if (menu.id !== `menu${this.rowIndex}`) {
                menu.style.display = 'none';
            }
        });

        if (this.menu.style.display === 'none') {
            const rect = this.triggerBtn.getBoundingClientRect();

            // Ajuster la position en fonction de l'espace disponible
            const rightSpace = window.innerWidth - rect.right;
            const bottomSpace = window.innerHeight - rect.top;

            // Position horizontale
            if (rightSpace < 200) {
                // Si pas assez d'espace à droite
                this.menu.style.right = `${window.innerWidth - rect.left + 5}px`;
                this.menu.style.left = 'auto';
            } else {
                this.menu.style.left = `${rect.right + 5}px`;
                this.menu.style.right = 'auto';
            }

            // Position verticale
            if (bottomSpace < this.menu.offsetHeight) {
                this.menu.style.bottom = `${window.innerHeight - rect.top}px`;
                this.menu.style.top = 'auto';
            } else {
                this.menu.style.top = `${rect.top}px`;
                this.menu.style.bottom = 'auto';
            }

            this.menu.style.display = 'block';
            document.addEventListener('click', this.handleClickOutside);
        } else {
            this.menu.style.display = 'none';
            document.removeEventListener('click', this.handleClickOutside);
        }
    },

    handleClickOutside(e) {
        if (!this.menu.contains(e.target) && !this.triggerBtn.contains(e.target)) {
            this.menu.style.display = 'none';
            document.removeEventListener('click', this.handleClickOutside);
        }
    },

    destroyed() {
        this.triggerBtn.removeEventListener('click', this.handleClick);
        document.removeEventListener('click', this.handleClickOutside);
    },
};

export default DropdownHook;
