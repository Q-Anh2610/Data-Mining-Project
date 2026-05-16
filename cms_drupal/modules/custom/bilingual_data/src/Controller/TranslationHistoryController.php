<?php

namespace Drupal\bilingual_data\Controller;

use Drupal\Core\Controller\ControllerBase;
use Drupal\Core\Database\Database;
use Symfony\Component\HttpFoundation\Request;

class TranslationHistoryController extends ControllerBase {

  public function list(Request $request) {
    $page = max(0, (int) $request->query->get('page', 0));
    $limit = 50;
    $offset = $page * $limit;

    $keyword = trim((string) $request->query->get('keyword', ''));

    try {
      $connection = Database::getConnection('default', 'supabase');

      $query = $connection->select('translation_history', 't')
        ->fields('t', [
          'id',
          'device_id',
          'input_text',
          'output_text',
          'is_favorite',
          'rating',
          'created_at',
        ])
        ->range($offset, $limit)
        ->orderBy('created_at', 'DESC');

      if ($keyword !== '') {
        $or = $query->orConditionGroup()
          ->condition('input_text', '%' . $connection->escapeLike($keyword) . '%', 'LIKE')
          ->condition('output_text', '%' . $connection->escapeLike($keyword) . '%', 'LIKE');

        $query->condition($or);
      }

      $results = $query->execute()->fetchAll();

      $rows = [];

      foreach ($results as $row) {
        $rows[] = [
          'data' => [
            $row->id,
            $row->device_id,
            $row->input_text,
            $row->output_text,
            $row->is_favorite ? 'Có' : 'Không',
            $row->rating ?? 'Chưa đánh giá',
            $row->created_at,
          ],
        ];
      }

      return [
        'intro' => [
          '#markup' => '
            <h2>Lịch sử dịch</h2>
            <p>Dữ liệu được đọc trực tiếp từ bảng <strong>translation_history</strong> trong Supabase.</p>
          ',
        ],

        'search_form' => [
          '#type' => 'inline_template',
          '#template' => '
            <form method="get" style="margin-bottom: 20px;">
              <input
                type="text"
                name="keyword"
                value="{{ keyword }}"
                placeholder="Tìm câu gốc hoặc câu dịch"
                style="width: 360px; padding: 8px;"
              >
              <button type="submit" style="padding: 8px 14px;">Tìm kiếm</button>
            </form>
          ',
          '#context' => [
            'keyword' => $keyword,
          ],
        ],

        'table' => [
          '#type' => 'table',
          '#header' => [
            'ID',
            'Thiết bị',
            'Câu gốc',
            'Kết quả dịch',
            'Yêu thích',
            'Đánh giá',
            'Thời gian',
          ],
          '#rows' => $rows,
          '#empty' => 'Không có dữ liệu lịch sử dịch.',
        ],

        'pager_custom' => [
          '#type' => 'inline_template',
          '#template' => '
            <div style="margin-top: 20px;">
              <a href="?page={{ prev }}&keyword={{ keyword }}">← Trang trước</a>
              <span style="margin: 0 16px;">Trang {{ current }}</span>
              <a href="?page={{ next }}&keyword={{ keyword }}">Trang sau →</a>
            </div>
          ',
          '#context' => [
            'prev' => max(0, $page - 1),
            'next' => $page + 1,
            'current' => $page + 1,
            'keyword' => $keyword,
          ],
        ],
      ];
    }
    catch (\Exception $e) {
      return [
        '#markup' => '
          <h2>Lỗi đọc bảng translation_history</h2>
          <p><strong>Chi tiết lỗi:</strong></p>
          <pre>' . htmlspecialchars($e->getMessage()) . '</pre>
        ',
      ];
    }
  }

}