# https://gist.github.com/darkSasori/b8f7acbc54e45fe3ac3b5a26e1715a90

"""
这个代码实现了一个经典的贪吃蛇游戏。
使用 curses 库在终端中创建图形界面。
游戏支持方向键控制蛇的移动，空格键暂停，ESC 键退出。
蛇可以穿过边界，吃到食物会变长并得分，撞到自己身体游戏结束。
"""
import time
import curses
from curses import KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN
from random import randint

WIDTH = 60
HEIGHT = 20

def walk_left(snake):
    snake.insert(0, [snake[0][0], snake[0][1]-1])
    if snake[0][1] <= 1: snake[0][1] = WIDTH - 1
    return snake


def walk_right(snake):
    snake.insert(0, [snake[0][0], snake[0][1]+1])
    if snake[0][1] >= WIDTH - 1: snake[0][1] = 1
    return snake


def walk_up(snake):
    snake.insert(0, [snake[0][0] -1, snake[0][1]])
    if snake[0][0] <= 0: snake[0][0] = 18
    return snake


def walk_down(snake):
    snake.insert(0, [snake[0][0] +1, snake[0][1]])
    if snake[0][0] >= HEIGHT - 1: snake[0][0] = 1
    return snake


def generate_food(snake):
    food = []
    while food == []:
        food = [randint(1, HEIGHT - 2), randint(1, WIDTH - 2)]
        if food in snake[1:]: food = []
    return food


def draw_snake(screen, snake, remove_last = True):
    # 绘制蛇头为'O'
    screen.addstr(snake[0][0], snake[0][1], 'O')
    # 绘制蛇身为'#'
    for segment in snake[1:]:
        screen.addstr(segment[0], segment[1], '#')
    
    if remove_last == False: return snake
    last = snake.pop()
    screen.addstr(last[0], last[1], ' ')
    return snake


def main(screen):
    #curses.curs_set(0)
    try:
        curses.curs_set(0)  # Try to make cursor invisible
    except curses.error:
        # Terminal doesn't support cursor visibility changes
        # The cursor will remain visible, but your program can continue
        pass
    screen.clear()
    screen.nodelay(1)
    screen.keypad(1)
    screen.timeout(150)
    screen.border(0)

    direction_functions = {
        KEY_LEFT: walk_left,
        KEY_RIGHT: walk_right,
        KEY_UP: walk_up,
        KEY_DOWN: walk_down
    }

    score = 0
    snake = [[4,4],[4,3],[4,2]]
    food = generate_food(snake)
    direction = KEY_RIGHT
    paused = False

    while True:
        screen.border(0)
        event = screen.getch()
        if event == 27:
            break

        if event == 32:
            paused = False if paused else True

        if paused:
            screen.addstr(0, 1, 'Paused')
            continue

        if event in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
            direction = event

        snake = direction_functions[direction](snake)
        if snake[0] in snake[1:]:
            break

        screen.addstr(0, 1, 'Score: {}'.format(score))
        snake = draw_snake(screen, snake, snake[0] != food)

        if snake[0] == food:
            food = generate_food(snake)
            score = score + 1

        screen.addstr(food[0], food[1], '*')

    return score

def show_intro():
    """在控制台中显示游戏介绍和开始提示"""
    print("\n" + "="*60)
    print(" " * 20 + "SNAKE GAME")
    print("="*60)
    print("\nWelcome to the classic Snake game!")
    print("\nControl the snake using arrow keys:")
    print("  - UP, DOWN, LEFT, RIGHT")
    print("\nRules:")
    print("  - Guide the snake to eat the food (*)")
    print("  - Each food increases your score by 1")
    print("  - The snake grows longer when it eats")
    print("  - Game ends if the snake hits itself")
    print("  - Snake can pass through walls")
    print("\nControls:")
    print("  - SPACE: Pause/Resume game")
    print("  - ESC: Quit game")
    
    # 等待用户输入
    while True:
        print("\nDo you want to start the game? [Y/n]: ", end="")
        try:
            key = input().strip().lower()
            if key == "" or key == "y":  # 回车或输入 y 都确认开始
                return True
            elif key == "n":
                return False
            else:
                print("Please enter 'y' for yes or 'n' for no.")
        except (EOFError, KeyboardInterrupt):
            return False

if __name__ == '__main__':
    if not show_intro():
        print("Game cancelled.")
        exit(0)

    curses.initscr()
    win = curses.newwin(HEIGHT, WIDTH, 0, 0)
    score = main(win)
    curses.endwin()
    print("\n" + "="*60)
    print('GAME OVER!')
    print('Congratulations, your score is: {}'.format(score))
    print("="*60)